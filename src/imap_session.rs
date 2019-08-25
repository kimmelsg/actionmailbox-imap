use crate::configuration::Configuration;

use std::net::TcpStream;

type ImapSessionType<'s> = &'s mut imap::Session<native_tls::TlsStream<TcpStream>>;

pub struct ImapSession<'a, 's> {
    session: ImapSessionType<'s>,
    config: &'a Configuration,
}

impl<'a, 's> ImapSession<'a, 's> {
    pub fn from(config: &'a Configuration, session: ImapSessionType<'s>) -> Self {
        ImapSession { session, config }
    }

    pub fn select_mailbox(&mut self) -> imap::error::Result<imap::types::Mailbox> {
        self.session.select(self.config.mailbox())
    }

    pub fn wait_for_messages(
        &mut self,
    ) -> imap::error::Result<std::collections::HashSet<imap::types::Seq>> {
        let idle = self.session.idle()?;

        println!("Begin listening for activity on IMAP server.");

        idle.wait_keepalive()?;

        println!("Activity detected.");

        std::thread::sleep(std::time::Duration::from_millis(800));

        println!("Grabbing new messages from mailbox.");

        self.session.search("NOT DELETED NOT SEEN")
    }

    pub fn mark_message_read(
        &mut self,
        id: u32,
    ) -> imap::error::Result<imap::types::ZeroCopy<Vec<imap::types::Fetch>>> {
        self.session.store(format!("{}", id), "+FLAGS (\\Seen)")
    }

    pub fn mark_message_unread(
        &mut self,
        id: u32,
    ) -> imap::error::Result<imap::types::ZeroCopy<Vec<imap::types::Fetch>>> {
        self.session.store(format!("{}", id), "-flags (\\Seen)")
    }

    pub fn mark_message_deleted(
        &mut self,
        id: u32,
    ) -> imap::error::Result<imap::types::ZeroCopy<Vec<imap::types::Fetch>>> {
        self.session.store(format!("{}", id), "+FLAGS (\\Deleted)")
    }
    pub fn get_message_body(&mut self, id: u32) -> Option<Vec<u8>> {
        let messages = match self.session.fetch(format!("{}", id), "RFC822") {
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

    pub fn expunge(&mut self) -> imap::error::Result<Vec<imap::types::Seq>> {
        self.session.expunge()
    }

    pub fn logout(&mut self) -> imap::error::Result<()> {
        self.session.logout()
    }
}
