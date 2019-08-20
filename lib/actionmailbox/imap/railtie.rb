module Actionmailbox
  module Imap
    class Railtie < ::Rails::Railtie
      rake_tasks do
        path = File.expand_path("../tasks/actionmailbox/ingress.rake", File.dirname(__dir__))
        load path
      end
    end
  end
end
