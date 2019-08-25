use config::{Config, ConfigError, File};
use serde::Deserialize;

#[derive(Deserialize, Debug)]
pub struct Configuration {
    server: String,
    port: i64,
    tls: bool,
    username: String,
    password: String,
    mailbox: String,
    workers: usize,
    wait: u64,
}

impl Configuration {
    pub fn new(filename: &str) -> Result<Configuration, ConfigError> {
        let mut config = Config::new();

        config.merge(File::with_name(filename))?;

        config.try_into::<Configuration>()
    }

    pub fn server(&self) -> &String {
        &self.server
    }

    pub fn port(&self) -> &i64 {
        &self.port
    }

    pub fn tls(&self) -> &bool {
        &self.tls
    }

    pub fn username(&self) -> &String {
        &self.username
    }

    pub fn password(&self) -> &String {
        &self.password
    }

    pub fn mailbox(&self) -> &String {
        &self.mailbox
    }

    pub fn workers(&self) -> usize {
        self.workers
    }

    pub fn wait(&self) -> u64 {
        self.wait
    }
}
