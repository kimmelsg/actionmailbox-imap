extern crate clap;
extern crate config;
extern crate ctrlc;
extern crate native_tls;
extern crate serde;
extern crate threadpool;

mod configuration;
mod processor;

use clap::{App, Arg, SubCommand};
use configuration::Configuration;
use processor::Processor;

fn main() {
    let matches = App::new("ActionMailbox::IMAP")
        .version("0.2.4")
        .author("Ethan Knowlton <eknowlton@gmail.com>")
        .about("IMAP client for ActionMailbox::IMAP")
        .arg(
            Arg::with_name("config")
                .short("c")
                .long("config")
                .value_name("FILE")
                .help("Sets a custom config file")
                .takes_value(true),
        )
        .subcommand(
            SubCommand::with_name("run")
                .about("Begins processing emails")
                .version("1.3"),
        )
        .get_matches();

    if let Some(_) = matches.subcommand_matches("run") {
        let config_file = matches
            .value_of("config")
            .unwrap_or("config/actionmailbox_imap.yaml");

        let mut config = match Configuration::new(config_file) {
            Ok(config) => config,
            Err(error) => {
                println!("Failed to build configuration.");
                println!("Error: {}", error);
                std::process::exit(64)
            }
        };

        config.set_environment_variables();

        if config.tls() == &false {
            println!("TLS is required. Please use with a server that supports it.");
            std::process::exit(64);
        }

        run(config)
    }

    println!("No command given. please run `actionmailbox-imap help` for help.");
}

fn run(config: Configuration) {
    let tls = match native_tls::TlsConnector::builder().build() {
        Ok(tls) => tls,
        Err(error) => {
            println!("Failed to create TLS Stream.");
            println!("Error: {}", error);
            std::process::exit(126);
        }
    };

    let client = match imap::connect(
        format!("{}:{}", config.server(), config.port()),
        &config.server()[..],
        &tls,
    ) {
        Ok(client) => client,
        Err(error) => {
            println!("Failed to create IMAP client and connect to server.");
            println!("Error: {}", error);
            std::process::exit(126);
        }
    };

    let mut session = match client.login(config.username(), config.password()) {
        Ok(session) => session,
        Err((error, _)) => {
            println!("Failed logging into the IMAP server. ");
            println!("Error: {}", error);
            std::process::exit(126);
        }
    };

    Processor::new(config, &mut session).process();
}
