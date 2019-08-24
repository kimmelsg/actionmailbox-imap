## `ActionMailbox::IMAP` Rust Client

In order to send IMAP messages to ActionMailbox, we could poll or we could connect to a server and listen for new messages. This rust client handles the long running process of listening for activity on a IMAP server better than I believe ruby would.

### What is the client?

Three things happen when you setup `ActionMailbox::IMAP`.

This rust client is started which will then connect to the IMAP server, login, select a mailbox, and send the IDLE command. This will then block and listen for any new activity on the mailbox.

Once a message is fetched from the server, the client will then pass a message to the ingress by issuing `bundle exec rails action_mailbox:ingress:imap`. When it calls this command it will forward the environment variables `URL` and `INGRESS_PASSWORD` to this command along with the body of the email message.

The ingress command will then relay the message to ActionMailbox via HTTP(S) as like the other ActionMailbox ingress options.

### Download

To download the client, visit the [releases](https://github.com/kimmelsg/actionmailbox-imap/releases) page. Ensure that version major and minor matches the major and minor of the gem you plan on using in your rails application.

### Configuration

The only configuration now is the number of worker threads you want available to process email messages. Each message gets processed in its own worker.

`config/actionmailbox_imap.yml`
```yaml
workers: 4
```
### Build

To build the client run...

```sh
$ cargo build (--release)
```

The resulting binary in `./target/(debug|release)/actionmailbox-imap` which should then be copied and ran from the root of your rails application. This only works as long as you have run `bundle exec rails imap:install` to generate the config file (`config/actionmailbox_imap.yml`)
