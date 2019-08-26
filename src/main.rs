extern crate clap;
extern crate config;
extern crate ctrlc;
extern crate native_tls;
extern crate serde;
extern crate threadpool;

mod configuration;
mod imap_client;
mod imap_session;
mod processor;

use clap::{App, Arg, SubCommand};
use configuration::Configuration;
use processor::process_emails;

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

    let config_file = matches
        .value_of("config")
        .unwrap_or("config/actionmailbox_imap.yaml");

    let config = match Configuration::new(config_file) {
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

    if let Some(_) = matches.subcommand_matches("run") {
        process_emails(config);
    }

    println!("No command given. please run `actionmailbox-imap help` for help.");
}
