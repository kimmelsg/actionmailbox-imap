require "actionmailbox/imap/messages"

module ActionMailbox
  module IMAP
    class Mailbox
      def initialize(adapter:, mailbox:)
        @adapter = adapter
        @mailbox = mailbox
      end

      def not_deleted
        adapter.messages_not_deleted.tap do |result|
          return false unless result # @TODO use Result object instead of false
          return Messages.new(adapter: adapter, message_ids: result)
        end
      end

      private

      attr_reader :adapter, :mailbox
    end
  end
end
