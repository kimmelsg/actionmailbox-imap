extern crate config;
extern crate ctrlc;
extern crate native_tls;
extern crate serde;
extern crate threadpool;

mod configuration;
mod imap_client;

use std::sync::mpsc::channel;
use threadpool::ThreadPool;

use std::io::Write;
use std::process::{Command, Stdio};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;

use configuration::ConfigObject;
use imap_client::ImapClient;

fn pass_to_ingress(
    body: Vec<u8>,
    url: &str,
    password: &str,
) -> std::io::Result<std::process::Output> {
    let mut child = Command::new("bundle")
        .env("URL", url)
        .env("INGRESS_PASSWORD", password)
        .args(&["exec", "rails", "action_mailbox:ingress:imap"])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()?;

    let mut_stdin = child.stdin.as_mut().unwrap();

    mut_stdin.write_all(body.as_slice())?;

    let output = child.wait_with_output()?;

    Ok(output)
}

fn main() {
    let config = match ConfigObject::new("config/actionmailbox_imap.yml") {
        Ok(config) => config,
        Err(error) => {
            println!("Failed to build configuration.");
            println!("Error: {}", error);
            std::process::exit(64)
        }
    };

    if config.tls() == &false {
        println!("TLS is required. Please use with a server that supports it.");
        std::process::exit(64);
    }

    let client = match ImapClient::new(&config) {
        Ok(client) => client,
        Err(error) => {
            println!("Failed to create IMAP client and connect to server.");
            println!("Error: {}", error);
            std::process::exit(126);
        }
    };

    println!("Connected to IMAP server and created client.");

    let mut session = match client.login() {
        Ok(session) => session,
        Err((error, _)) => {
            println!("Failed logging into the IMAP server. ");
            println!("Error: {}", error);
            std::process::exit(126);
        }
    };

    println!("Logged into the IMAP server.");

    match session.select(config.mailbox()) {
        Err(error) => {
            println!("A error occured selecting the inbox.");
            println!("Error: {}", error);
            std::process::exit(126);
        }
        _ => (),
    }

    println!("Selected '{}' mailbox.", config.mailbox());

    let running = Arc::new(AtomicBool::new(true));
    let r = running.clone();

    ctrlc::set_handler(move || {
        r.store(false, Ordering::SeqCst);
    })
    .expect("Error listening for SIGTERM.");

    'idle: loop {
        let pool = ThreadPool::new(config.workers());
        let (tx, rx) = channel();

        let idle = match session.idle() {
            Err(error) => {
                println!("Failed to send command: IDLE");
                println!("IMAP server may not support IDLE command.");
                println!("Error: {}", error);
                std::process::exit(126);
            }
            Ok(idle) => idle,
        };

        println!("Begin listening for activity on IMAP server.");

        match idle.wait_keepalive() {
            Err(error) => {
                println!("Failed to wait and keepalive.");
                println!("Error: {}", error);
                std::process::exit(126);
            }
            _ => (),
        }

        println!("Activity detected.");

        std::thread::sleep(std::time::Duration::from_millis(800));

        println!("Grabbing new messages from mailbox.");

        let mut message_ids = match session.search("NOT DELETED NOT SEEN") {
            Ok(message_ids) => message_ids,
            Err(error) => {
                println!("Failed to search for NOT DELETED NOT SEEN messages.");
                println!("Error: {}", error);
                std::process::exit(126);
            }
        };

        for message_id in message_ids.drain() {
            println!("Passing message to ingress: Seq {}", message_id);
            let job = tx.clone();

            match session.store(format!("{}", message_id), "+FLAGS (\\Seen)") {
                Err(error) => {
                    println!("Failed to mark message as Seen: Seq {}", message_id);
                    println!("Error: {}", error);
                }
                _ => (),
            }

            // fetch message
            let messages = match session.fetch(format!("{}", message_id), "RFC822") {
                Ok(messages) => messages,
                Err(error) => {
                    println!("Failed to fetch message: Seq {}", message_id);
                    println!("Error: {}", error);
                    continue;
                }
            };

            let message = match messages.iter().next() {
                Some(message) => message,
                None => {
                    println!("Failed to fetch message: Seq {}", message_id);

                    match session.store(format!("{}", message_id), "-flags (\\Seen)") {
                        Err(error) => {
                            println!("Failed to fetch message: Seq {}", message_id);
                            println!("Error: {}", error);
                        }
                        _ => (),
                    }
                    continue;
                }
            };

            let body = match message.body() {
                Some(body) => body,
                None => {
                    println!("Failed to read body or empty body: Seq {}", message_id);

                    match session.store(format!("{}", message_id), "-FLAGS (\\Seen)") {
                        Err(error) => {
                            println!("Error marking message unread: Seq {}", message_id);
                            println!("Error: {}", error);
                        }
                        _ => (),
                    }

                    continue;
                }
            };

            let url = match std::env::var("URL") {
                Ok(url) => url,
                _ => {
                    println!("Environment variable URL missing. URL is required.");
                    std::process::exit(64);
                }
            };

            let ingress_password = match std::env::var("INGRESS_PASSWORD") {
                Ok(url) => url,
                _ => {
                    println!("Environment variable URL missing. URL is required.");
                    std::process::exit(64);
                }
            };

            let body: Vec<u8> = body.iter().cloned().collect();

            pool.execute(
                move || match pass_to_ingress(body, &url[..], &ingress_password[..]) {
                    Ok(output) => {
                        let response = match String::from_utf8(output.stdout) {
                            Ok(response) => response,
                            Err(_) => String::from("Error reading STDOUT"),
                        };

                        println!(
                            "Seq {} :: Response from ingress command: {}",
                            message_id, response
                        );

                        if output.status.success() {
                            match job.send(Ok(message_id)) {
                                Err(error) => {
                                    println!("Seq {} :: Failed to send result", message_id);
                                    println!("Seq {} :: Error: {}", message_id, error);
                                }
                                _ => (),
                            }
                            return;
                        }

                        match job.send(Err(message_id)) {
                            Err(error) => {
                                println!("Seq {} :: Failed to send result", message_id);
                                println!("Seq {} :: Error: {}", message_id, error);
                            }
                            _ => (),
                        }
                    }
                    Err(error) => {
                        println!("Failed to pass to ingress.");
                        println!("Error: {}", error);
                        std::process::exit(126);
                    }
                },
            );
        }

        while running.load(Ordering::SeqCst) {
            while pool.active_count() > 0 && pool.queued_count() > 0 {
                match rx.try_recv() {
                    Ok(result) => match result {
                        Ok(message_id) => {
                            println!("Message successfully passed to ingress. Seq {}", message_id);

                            match session.store(format!("{}", message_id), "+FLAGS (\\Deleted)") {
                                Err(error) => {
                                    println!("Error deleting message: Seq {}", message_id);
                                    println!("Error: {}", error);
                                }
                                _ => (),
                            }
                        }
                        Err(message_id) => {
                            match session.store(format!("{}", message_id), "-FLAGS (\\Seen)") {
                                Err(error) => {
                                    println!("Error marking message unread: Seq {}", message_id);
                                    println!("Error: {}", error);
                                }
                                _ => (),
                            }
                        }
                    },
                    _ => (),
                }
            }

            std::mem::drop(tx);

            while let Ok(result) = rx.recv() {
                match result {
                    Ok(message_id) => {
                        println!("Message successfully passed to ingress. Seq {}", message_id);

                        match session.store(format!("{}", message_id), "+FLAGS (\\Deleted)") {
                            Err(error) => {
                                println!("Error deleting message: Seq {}", message_id);
                                println!("Error: {}", error);
                            }
                            _ => (),
                        }
                    }
                    Err(message_id) => {
                        match session.store(format!("{}", message_id), "-FLAGS (\\Seen)") {
                            Err(error) => {
                                println!("Error marking message unread: Seq {}", message_id);
                                println!("Error: {}", error);
                            }
                            _ => (),
                        }
                    }
                }
            }

            match session.expunge() {
                Err(error) => {
                    println!("Failed to expunge deleted messages.");
                    println!("Error: {}", error);
                }
                _ => (),
            }

            continue 'idle;
        }

        println!("Recived SIGINT, exiting...");
        std::process::exit(0);
    }
}
