use crate::configuration::Configuration;
use imap::error::Error;
use std::net::TcpStream;

type ImapClientType = imap::Client<native_tls::TlsStream<TcpStream>>;

pub struct ImapClient<'a> {
    client: ImapClientType,
    config: &'a Configuration,
}

impl<'a> ImapClient<'a> {
    pub fn new(config: &'a Configuration) -> Result<Self, Error> {
        let tls = native_tls::TlsConnector::builder().build()?;

        let client = imap::connect(
            format!("{}:{}", config.server(), config.port()),
            &config.server()[..],
            &tls,
        )?;

        Ok(ImapClient { client, config })
    }

    pub fn login(
        self,
    ) -> Result<imap::Session<native_tls::TlsStream<TcpStream>>, (Error, ImapClientType)> {
        self.client
            .login(self.config.username(), self.config.password())
    }
}
