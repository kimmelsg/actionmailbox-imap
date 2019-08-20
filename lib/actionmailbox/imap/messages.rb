require "actionmailbox/imap/message"

module ActionMailbox
  module IMAP
    class Messages
      def initialize(adapter:, message_ids:)
        @adapter = adapter
        @message_ids = message_ids
      end

      def take(n)
        taken_ids = message_ids.take(n)
        Messages.new(adapter: adapter, message_ids: taken_ids)
      end

      def length
        message_ids.length
      end

      def each
        return unless block_given? # @TODO Need to test this branch

        message_ids.each do |id|
          yield Message.new(adapter: adapter, id: id)
        end
      end

      private

      attr_reader :adapter, :message_ids
    end
  end
end
