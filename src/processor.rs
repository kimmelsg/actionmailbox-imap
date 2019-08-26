use crate::configuration::Configuration;

use std::net::TcpStream;
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

type ImapSession = imap::Session<native_tls::TlsStream<TcpStream>>;

pub struct Processor<'s> {
    session: &'s mut ImapSession,
    config: Configuration,
}

impl<'s> Processor<'s> {
    pub fn new(config: Configuration, session: &'s mut ImapSession) -> Self {
        Self { config, session }
    }

    pub fn process(&mut self) {
        println!("Logged into the IMAP server.");

        match self.select_mailbox() {
            Err(error) => {
                println!("A error occured selecting the inbox.");
                println!("Error: {}", error);
                std::process::exit(126);
            }
            _ => (),
        }

        println!("Selected '{}' mailbox.", self.config.mailbox());

        let running = Arc::new(AtomicBool::new(true));
        let r = running.clone();

        ctrlc::set_handler(move || {
            r.store(false, Ordering::SeqCst);
        })
        .expect("Error listening for SIGINT.");

        'idle: loop {
            let pool = ThreadPool::new(self.config.workers());
            let (tx, rx) = channel();

            while running.load(Ordering::SeqCst) {
                let mut messages = self.wait_for_messages();

                for id in messages.drain() {
                    println!("UID {} :: Passing message to ingress.", id);
                    let job = tx.clone();

                    match self.mark_message_read(id) {
                        Err(error) => {
                            println!("UID {} :: Failed to mark message as read.", id);
                            println!("UID {} :: Error: {}", id, error);
                        }
                        _ => (),
                    }

                    let body = match self.get_message_body(id) {
                        Some(body) => body,
                        None => {
                            println!("UID {} :: Failed to read body or empty body.", id);
                            self.mark_message_for_retry(id);
                            continue;
                        }
                    };

                    let url = self.config.url().unwrap();

                    let ingress_password = self.config.ingress_password().unwrap();

                    pool.execute(move || {
                        match pass_to_ingress(body, &url[..], &ingress_password[..]) {
                            Ok(output) => {
                                let response = match String::from_utf8(output.stdout) {
                                    Ok(response) => response,
                                    Err(_) => String::from("Error reading STDOUT"),
                                };

                                println!(
                                    "UID {} :: Response from ingress command: {}",
                                    id, response
                                );

                                if output.status.success() {
                                    match job.send(Ok(id)) {
                                        Err(error) => {
                                            println!("UID {} :: Failed to send result", id);
                                            println!("UID {} :: Error: {}", id, error);
                                        }
                                        _ => (),
                                    }
                                    return;
                                }

                                match job.send(Err(id)) {
                                    Err(error) => {
                                        println!("UID {} :: Failed to send result", id);
                                        println!("UID {} :: Error: {}", id, error);
                                    }
                                    _ => (),
                                }
                            }
                            Err(error) => {
                                println!("UID {} :: Failed to pass to ingress.", id);
                                println!("UID {} :: Error: {}", id, error);

                                match job.send(Err(id)) {
                                    Err(error) => {
                                        println!("UID {} :: Failed send command", id);
                                        println!("UID {} :: Error: {}", id, error);
                                    }
                                    _ => (),
                                }
                            }
                        }
                    });
                }

                while pool.active_count() > 0 && pool.queued_count() > 0 {
                    match rx.try_recv() {
                        Ok(result) => match result {
                            Ok(id) => {
                                println!("UID {} :: Message successfully passed to ingress.", id);
                                self.mark_message_as_success(id);
                            }
                            Err(id) => self.mark_message_as_failed(id),
                        },
                        _ => (),
                    }
                }

                std::mem::drop(tx);

                while let Ok(result) = rx.recv() {
                    match result {
                        Ok(id) => {
                            println!("UID {} :: Message successfully passed to ingress. ", id);
                            self.mark_message_as_success(id);
                        }
                        Err(id) => self.mark_message_as_failed(id),
                    }
                }

                match self.expunge() {
                    Err(error) => {
                        println!("Failed to expunge deleted messages.");
                        println!("Error: {}", error);
                    }
                    _ => (),
                }

                continue 'idle;
            }

            self.logout().expect("Failed to logout.");
            println!("Recived SIGINT, exiting...");
            std::process::exit(0);
        }
    }

    fn select_mailbox(&mut self) -> imap::error::Result<imap::types::Mailbox> {
        self.session.select(self.config.mailbox())
    }

    fn wait_for_messages(&mut self) -> std::collections::HashSet<imap::types::Uid> {
        let idle = match self.session.idle() {
            Ok(idle) => idle,
            Err(error) => {
                println!("Failed to send IDLE command.");
                println!("Error: {}", error);
                std::process::exit(126);
            }
        };

        println!("Begin listening for activity on IMAP server.");

        match idle.wait_keepalive() {
            Err(error) => {
                println!("Failed to wait for messages.");
                println!("Error: {}", error);
                std::process::exit(126);
            }
            _ => (),
        };

        println!("Activity detected.");

        std::thread::sleep(std::time::Duration::from_millis(self.config.wait()));

        println!("Grabbing new messages from mailbox.");

        match self.session.uid_search("NOT DELETED NOT SEEN NOT FLAGGED") {
            Ok(messages) => messages,
            Err(error) => {
                println!("Failed to wait for messages.");
                println!("Error: {}", error);
                std::process::exit(126);
            }
        }
    }

    fn mark_message_for_retry(&mut self, id: u32) {
        match self.mark_message_unread(id) {
            Err(error) => {
                println!("UID {} :: Error marking message unread.", id);
                println!("UID {} :: Error: {}", id, error);
            }
            _ => (),
        };
    }

    fn mark_message_as_failed(&mut self, id: u32) {
        match self.mark_message_flagged(id) {
            Err(error) => {
                println!("UID {} :: Error marking message flagged.", id);
                println!("UID {} :: Error: {}", id, error);
            }
            _ => (),
        }
    }

    fn mark_message_as_success(&mut self, id: u32) {
        match self.mark_message_deleted(id) {
            Err(error) => {
                println!("UID {} :: Error marking message unread.", id);
                println!("UID {} :: Error: {}", id, error);
            }
            _ => (),
        };
    }

    fn mark_message_flagged(
        &mut self,
        id: u32,
    ) -> imap::error::Result<imap::types::ZeroCopy<Vec<imap::types::Fetch>>> {
        self.session
            .uid_store(format!("{}", id), "+FLAGS (\\Flagged)")
    }

    fn mark_message_read(
        &mut self,
        id: u32,
    ) -> imap::error::Result<imap::types::ZeroCopy<Vec<imap::types::Fetch>>> {
        self.session.uid_store(format!("{}", id), "+FLAGS (\\Seen)")
    }

    fn mark_message_unread(
        &mut self,
        id: u32,
    ) -> imap::error::Result<imap::types::ZeroCopy<Vec<imap::types::Fetch>>> {
        self.session.uid_store(format!("{}", id), "-flags (\\Seen)")
    }

    fn mark_message_deleted(
        &mut self,
        id: u32,
    ) -> imap::error::Result<imap::types::ZeroCopy<Vec<imap::types::Fetch>>> {
        self.session
            .uid_store(format!("{}", id), "+FLAGS (\\Deleted)")
    }

    fn get_message_body(&mut self, id: u32) -> Option<Vec<u8>> {
        let messages = match self.session.uid_fetch(format!("{}", id), "RFC822") {
            Ok(messages) => messages,
            Err(_) => return None,
        };

        let message = match messages.iter().next() {
            Some(message) => message,
            None => return None,
        };

        let body: Vec<u8> = message.body().unwrap().iter().cloned().collect::<Vec<u8>>();
        Some(body)
    }

    fn expunge(&mut self) -> imap::error::Result<Vec<imap::types::Uid>> {
        self.session.expunge()
    }

    fn logout(&mut self) -> imap::error::Result<()> {
        self.session.logout()
    }
}
