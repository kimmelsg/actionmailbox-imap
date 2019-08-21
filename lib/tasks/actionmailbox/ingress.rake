require "actionmailbox/imap/adapters/net_imap"

namespace :action_mailbox do
  namespace :ingress do
    task :environment do
      require "active_support"
      require "active_support/core_ext/object/blank"
      require "action_mailbox/relayer"
    end

    desc "Relays inbound IMAP email to Action Mailbox (URL and INGRESS_PASSWORD required)"
    task imap: "action_mailbox:ingress:environment" do
      url, password = ENV.values_at("URL", "INGRESS_PASSWORD")

      config = Rails.application.config_for(:actionmailbox_imap)

      adapter = ActionMailbox::IMAP::Adapters::NetImap.new(
        server: config[:server],
        port: config[:port],
        usessl: config[:usessl]
      )

      imap = ActionMailbox::IMAP::Base.new(adapter: adapter)

      imap.login(username: config[:username], password: config[:password])

      mailbox = imap.mailbox(config[:ingress_mailbox])

      relayer = ActionMailbox::Relayer.new(url: url, password: password)

      mailbox.messages.take(config[:take]).each do |message|
        relayer.relay(message.rfc822).tap do |result|
          message.delete if result.success?
        end
      end

      imap.disconnect
    end
  end
end
