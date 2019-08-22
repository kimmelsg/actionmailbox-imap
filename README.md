# ActionMailbox::IMAP
[![CircleCI](https://circleci.com/gh/kimmelsg/actionmailbox-imap.svg?style=svg)](https://circleci.com/gh/kimmelsg/actionmailbox-imap) 
[![RubyGems](https://badge.fury.io/rb/actionmailbox-imap.svg)](https://rubygems.org/gems/actionmailbox-imap) 
[![Standard](https://camo.githubusercontent.com/58fbab8bb63d069c1e4fb3fa37c2899c38ffcd18/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f636f64655f7374796c652d7374616e646172642d627269676874677265656e2e737667)](https://github.com/testdouble/standard)

A IMAP relay for ActionMailbox.

This is a very simple gem that provides a rake task which will connect to an IMAP server, grab some (`take`) emails, attempt to relay them to ActionMailbox.

If the rake task successfully relays a message to ActionMailbox then it will flag the message as "Deleted" on the IMAP server, and continue to the next message.

If the rake task fails to relay a message to ActionMailbox then it will ignore it and move on to the next message leaving the message on the IMAP server.

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

Update the `config/imap.yml` that was generated to include server and credentials information, `ingress_mailbox` and an appropriate `take` amount ( the amount of emails to grab in a single run ).

Run or schedule `rails action_mailbox:ingress:imap URL="http://localhost/rails/action_mailbox/relay/inbound_email" INGRESS_PASSWORD="YourIngressPassword"` to run at a selected interval. 

The command behaves much like that of the other `action_mailbox:ingress:...` commands in that it relays the message the same way. Although messages should be piped to the other ingress commands and `rails action_mailbox:ingress:imap ...` needs to be scheduled appropriately.

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
