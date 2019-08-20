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
      adapter = ActionMailbox::IMAP::Adapters::NetImap.new(
        server: "outlook.office365.com",
        port: 993,
        usessl: true
      )

      imap = ActionMailbox::IMAP::Base.new(adapter: adapter)

      imap.login(username: "walter2@kimmel.com", password: "Kimmel trench capon2")

      mailbox = imap.select_mailbox("INBOX")

      mailbox.not_deleted.each do |message|
        pp message.get_id
      end
    end
  end
end
