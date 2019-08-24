# ActionMailbox::IMAP
[![CircleCI](https://circleci.com/gh/kimmelsg/actionmailbox-imap.svg?style=svg)](https://circleci.com/gh/kimmelsg/actionmailbox-imap)
[![RubyGems](https://badge.fury.io/rb/actionmailbox-imap.svg)](https://rubygems.org/gems/actionmailbox-imap)
[![Standard](https://camo.githubusercontent.com/58fbab8bb63d069c1e4fb3fa37c2899c38ffcd18/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f636f64655f7374796c652d7374616e646172642d627269676874677265656e2e737667)](https://github.com/testdouble/standard)

A IMAP relay for ActionMailbox.

This is a very simple gem that provides a rake task attempt to relay messsages to ActionMailbox from the [ActionMailbox::IMAP Client](https://github.com/kimmelsg/actionmailbox-imap/blob/master/CLIENT.md).

If a message is successuflly relayed to ActionMailbox, then the message will be marked deleted.
If a message is not successfully relayed to ActionMailbox, then the message will be marked Unread in order to be processed again later.

### Why it was created

It seems that there is no plans to create some sort of IMAP implementation relay in ActionMailbox.
https://github.com/rails/actionmailbox/issues/14

There is probably a reason for this. We did not want to setup or maintain a mailserver which would probably be the route to go for a robust inbound email application.

## Usage

### Install ActionMailbox

Per [ActionMailbox documentation](https://edgeguides.rubyonrails.org/action_mailbox_basics.html)

```bash
$ rails action_mailbox:install
$ rails db:migrate
```

```ruby
# config/environments/production.rb
config.action_mailbox.ingress = :relay
```

```bash
$ rails credentials:edit
```

```yaml
action_mailbox:
    ingress_password: "YourIngressPassword"
```


### Install ActionMailbox::IMAP

```bash
$ rails g imap:install
```

Prepare your IMAP server and account by ensuring/creating the mailboxes for `ingress_mailbox`, ex: "INBOX".

Update the `config/imap.yml` that was generated to include server and credentials information, `mailbox`. Currently SSL is required.

Run the [ActionMailbox::IMAP Client](https://github.com/kimmelsg/actionmailbox-imap/blob/master/CLIENT.md) like so `URL=... INGRESS_PASSWORD=... ./actionmailbox-imap` to begin processing emails.

`NOTE: Running the client will begin immediately begin processing unread emails in the configured mailbox. The server (URL) needs to be running. You may also want to start from a empty, or plan on watching the process to ensure no performance issues occur.`

### Rake Task

The rake task behaves much like that of the other `action_mailbox:ingress:...` commands in that it relays the message the same way.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'actionmailbox-imap'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install actionmailbox-imap
```

## Contributing

Want to contribute? Please do. PR's and passing tests (lint, test) will be required.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
