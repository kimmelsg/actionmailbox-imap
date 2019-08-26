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
    url: Option<String>,
    ingress_password: Option<String>,
}

impl Configuration {
    pub fn new(filename: &str) -> Result<Configuration, ConfigError> {
        let mut config = Config::new();

        config.merge(File::with_name(filename))?;

        config.try_into::<Configuration>()
    }

    pub fn set_environment_variables(&mut self) {
        if self.url.is_none() {
            self.url.replace(match std::env::var("URL") {
                Ok(url) => url,
                _ => {
                    println!("Environment (URL) or config (url) variable is required.");
                    std::process::exit(64);
                }
            });
        }

        if self.ingress_password.is_none() {
            self.ingress_password
                .replace(match std::env::var("INGRESS_PASSWORD") {
                    Ok(ingress_password) => ingress_password,
                    _ => {
                        println!("Environment (INGRESS_PASSWORD) or config (ingress_password) variable is required.");
                        std::process::exit(64);
                    }
                });
        }
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

    pub fn url(&mut self) -> Option<String> {
        self.url.take()
    }

    pub fn ingress_password(&mut self) -> Option<String> {
        self.ingress_password.take()
    }
}
