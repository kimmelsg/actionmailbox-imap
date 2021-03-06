use config::{Config, ConfigError, File};
use serde::Deserialize;

#[derive(Deserialize, Debug, Clone)]
pub struct Configuration {
    server: String,
    port: i64,
    tls: bool,
    username: Option<String>,
    password: Option<String>,
    mailbox: String,
    workers: usize,
    wait: u64,
    url: Option<String>,
    ingress_password: Option<String>,
    ruby: Option<String>,
    bundle: Option<String>,
}

impl Configuration {
    pub fn new(filename: &str) -> Result<Configuration, ConfigError> {
        let mut config = Config::new();

        config.merge(File::with_name(filename))?;

        config.try_into::<Configuration>()
    }

    pub fn set_environment_variables(&mut self) {
        if self.username.is_none() {
            self.username.replace(with_env("USERNAME"));
        }

        if self.password.is_none() {
            self.password.replace(with_env("PASSWORD"));
        }

        if self.url.is_none() {
            self.url.replace(with_env("URL"));
        }

        if self.ingress_password.is_none() {
            self.ingress_password.replace(with_env("INGRESS_PASSWORD"));
        }

        if self.ruby.is_none() {
            self.ruby.replace(with_env("RUBY"));
        }

        if self.bundle.is_none() {
            self.bundle.replace(with_env("BUNDLE"));
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

    pub fn username(&self) -> String {
        match self.username.clone() {
            Some(username) => username,
            None => {
                println!("Failed getting USERNAME.");
                std::process::exit(126);
            }
        }
    }

    pub fn password(&self) -> String {
        match self.password.clone() {
            Some(password) => password,
            None => {
                println!("Failed getting PASSWORD.");
                std::process::exit(126);
            }
        }
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

    pub fn url(&mut self) -> String {
        match self.url.take() {
            Some(url) => url,
            None => {
                println!("Failed getting URL.");
                std::process::exit(126);
            }
        }
    }

    pub fn ingress_password(&mut self) -> String {
        match self.ingress_password.take() {
            Some(ingress_password) => ingress_password,
            None => {
                println!("Failed getting INGRESS_PASSWORD.");
                std::process::exit(126);
            }
        }
    }

    pub fn ruby(&mut self) -> String {
        match self.ruby.take() {
            Some(ruby) => ruby,
            None => {
                println!("Failed getting RUBY.");
                std::process::exit(126);
            }
        }
    }

    pub fn bundle(&mut self) -> String {
        match self.bundle.take() {
            Some(bundle) => bundle,
            None => {
                println!("Failed getting BUNDLE.");
                std::process::exit(126);
            }
        }
    }
}

fn with_env(var: &str) -> String {
    match std::env::var(var) {
        Ok(var) => var,
        _ => {
            println!(
                "Environment ({}) or config ({}) variable is required.",
                var,
                var.to_ascii_lowercase()
            );
            std::process::exit(64);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_it_can_parse_all_configuration_file() {
        let result = Configuration::new("config/actionmailbox_imap_all.yml");
        assert!(result.is_ok());
    }

    #[test]
    fn test_it_can_parse_minimum_configuration_file() {
        let result = Configuration::new("config/actionmailbox_imap_minimum.yml");
        assert!(result.is_ok());
    }

    #[test]
    fn test_it_will_use_environment_variables() {
        std::env::set_var("USERNAME", "username");
        std::env::set_var("PASSWORD", "password");
        std::env::set_var("URL", "http://localhost:3000");
        std::env::set_var("INGRESS_PASSWORD", "ingresspassword");
        std::env::set_var("RUBY", "ruby");
        std::env::set_var("BUNDLE", "bundle");

        let result = Configuration::new("config/actionmailbox_imap_minimum.yml");

        assert!(result.is_ok());

        let mut config = result.unwrap();

        config.set_environment_variables();

        assert_eq!(config.username(), String::from("username"));
        assert_eq!(config.password(), String::from("password"));
        assert_eq!(config.url(), String::from("http://localhost:3000"));
        assert_eq!(config.ingress_password(), String::from("ingresspassword"));
        assert_eq!(config.ruby(), String::from("ruby"));
        assert_eq!(config.bundle(), String::from("bundle"));
    }
}
