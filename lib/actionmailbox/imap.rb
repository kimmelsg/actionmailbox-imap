require "actionmailbox/imap/railtie"
require "actionmailbox/imap/mailbox"

module ActionMailbox
  module IMAP
    class Base
      def initialize(adapter:)
        @adapter = adapter
      end

      def authenticate(username:, password:)
        adapter.authenticate(username: username, password: password)
      end

      def select_mailbox(mailbox)
        adapter.select_mailbox(mailbox).tap do |result|
          return false unless result # @TODO use Result object instead of false
          return Mailbox.new(adapter: adapter, mailbox: mailbox)
        end
      end

      def disconnect
        adapter.disconnect
      end

      private

      attr_reader :adapter
    end
  end
end
