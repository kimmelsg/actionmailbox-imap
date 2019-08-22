module ActionMailbox
  module IMAP
    class Message
      RFC822 = "RFC822".freeze

      def initialize(adapter:, id:)
        @adapter = adapter
        @id = id
      end

      def rfc822
        adapter.fetch_message_attr(id, RFC822)
      end

      def delete
        adapter.delete_message(id)
      end

      def mark_read
        adapter.mark_message_seen(id)
      end

      def mark_unread
        adapter.mark_message_unseen(id)
      end

      private

      attr_reader :adapter, :id
    end
  end
end
