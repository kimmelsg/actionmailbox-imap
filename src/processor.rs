use crate::configuration::Configuration;
use crate::imap_client::ImapClient;
use crate::imap_session::ImapSession;

use std::sync::mpsc::channel;
use threadpool::ThreadPool;

use std::io::Write;
use std::process::{Command, Stdio};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;

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

pub fn process_emails(config: Configuration) {
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

    let mut session = ImapSession::from(&config, &mut session);

    println!("Logged into the IMAP server.");

    match session.select_mailbox() {
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
        r.store(false, Ordering::UidCst);
    })
    .expect("Error listening for SIGINT.");

    'idle: loop {
        let pool = ThreadPool::new(config.workers());
        let (tx, rx) = channel();

        let mut messages = match session.wait_for_messages() {
            Err(error) => {
                println!("Failed to wait and keepalive.");
                println!("Error: {}", error);
                std::process::exit(126);
            }
            Ok(messages) => messages,
        };

        for message_id in messages.drain() {
            println!("Passing message to ingress: Uid {}", message_id);
            let job = tx.clone();

            match session.mark_message_read(message_id) {
                Err(error) => {
                    println!("Failed to mark message as Seen: Uid {}", message_id);
                    println!("Error: {}", error);
                }
                _ => (),
            }

            let body = match session.get_message_body(message_id) {
                Some(body) => body,
                None => {
                    println!("Failed to read body or empty body: Uid {}", message_id);

                    match session.mark_message_unread(message_id) {
                        Err(error) => {
                            println!("Error marking message unread: Uid {}", message_id);
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

                    match session.mark_message_unread(message_id) {
                        Err(error) => {
                            println!("Failed to mark message as unread.");
                            println!("Error: {}", error);
                        }
                        _ => (),
                    }

                    std::process::exit(64);
                }
            };

            let ingress_password = match std::env::var("INGRESS_PASSWORD") {
                Ok(url) => url,
                _ => {
                    println!("Environment variable URL missing. URL is required.");

                    match session.mark_message_unread(message_id) {
                        Err(error) => {
                            println!("Failed to mark message as unread.");
                            println!("Error: {}", error);
                        }
                        _ => (),
                    }

                    std::process::exit(64);
                }
            };

            pool.execute(
                move || match pass_to_ingress(body, &url[..], &ingress_password[..]) {
                    Ok(output) => {
                        let response = match String::from_utf8(output.stdout) {
                            Ok(response) => response,
                            Err(_) => String::from("Error reading STDOUT"),
                        };

                        println!(
                            "Uid {} :: Response from ingress command: {}",
                            message_id, response
                        );

                        if output.status.success() {
                            match job.send(Ok(message_id)) {
                                Err(error) => {
                                    println!("Uid {} :: Failed to send result", message_id);
                                    println!("Uid {} :: Error: {}", message_id, error);
                                }
                                _ => (),
                            }
                            return;
                        }

                        match job.send(Err(message_id)) {
                            Err(error) => {
                                println!("Uid {} :: Failed to send result", message_id);
                                println!("Uid {} :: Error: {}", message_id, error);
                            }
                            _ => (),
                        }
                    }
                    Err(error) => {
                        println!("Uid {} :: Failed to pass to ingress.", message_id);
                        println!("Uid {} :: Error: {}", message_id, error);

                        match job.send(Err(message_id)) {
                            Err(error) => {
                                println!("Uid {} :: Failed send command", message_id);
                                println!("Uid {} :: Error: {}", message_id, error);
                            }
                            _ => (),
                        }
                    }
                },
            );
        }

        while running.load(Ordering::UidCst) {
            while pool.active_count() > 0 && pool.queued_count() > 0 {
                match rx.try_recv() {
                    Ok(result) => match result {
                        Ok(message_id) => {
                            println!("Message successfully passed to ingress. Uid {}", message_id);

                            match session.mark_message_deleted(message_id) {
                                Err(error) => {
                                    println!("Error deleting message: Uid {}", message_id);
                                    println!("Error: {}", error);
                                }
                                _ => (),
                            }
                        }
                        Err(message_id) => match session.mark_message_flagged(message_id) {
                            Err(error) => {
                                println!("Error marking flagged unread: Uid {}", message_id);
                                println!("Error: {}", error);
                            }
                            _ => (),
                        },
                    },
                    _ => (),
                }
            }

            std::mem::drop(tx);

            while let Ok(result) = rx.recv() {
                match result {
                    Ok(message_id) => {
                        println!("Message successfully passed to ingress. Uid {}", message_id);

                        match session.mark_message_deleted(message_id) {
                            Err(error) => {
                                println!("Error deleting message: Uid {}", message_id);
                                println!("Error: {}", error);
                            }
                            _ => (),
                        }
                    }
                    Err(message_id) => match session.mark_message_flagged(message_id) {
                        Err(error) => {
                            println!("Error marking flagged unread: Uid {}", message_id);
                            println!("Error: {}", error);
                        }
                        _ => (),
                    },
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

        session.logout().expect("Failed to logout.");
        println!("Recived SIGINT, exiting...");
        std::process::exit(0);
    }
}
