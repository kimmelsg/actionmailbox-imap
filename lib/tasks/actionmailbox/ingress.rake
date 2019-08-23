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

      if url.blank? || password.blank?
        print "URL and INGRESS_PASSWORD are required"
        exit 64 # EX_USAGE
      end

      ActionMailbox::Relayer.new(url: url, password: password).relay(STDIN.read).tap do |result|
        print result.message

        if result.success?
          exit 0
        elsif result.transient_failure?
          exit 75 # EX_TEMPFAIL
        else
          exit 69 # EX_UNAVAILABLE
        end
      end
    end
  end
end
