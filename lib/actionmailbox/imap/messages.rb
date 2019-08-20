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

      private

      attr_reader :adapter, :message_ids
    end
  end
end
