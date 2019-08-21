require "actionmailbox/imap/messages"

module ActionMailbox
  module IMAP
    class Mailbox
      def initialize(adapter:, mailbox:)
        @adapter = adapter
        @mailbox = mailbox
      end

      def messages
        result = adapter.messages_not_deleted
        Messages.new(adapter: adapter, message_ids: result)
      end

      private

      attr_reader :adapter, :mailbox
    end
  end
end
