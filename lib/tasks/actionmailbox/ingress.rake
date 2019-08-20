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
      print "IMAP Ingress"
    end
  end
end
