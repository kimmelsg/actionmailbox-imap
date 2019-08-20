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

      def move_to(mailbox)
        adapter.move_message_to(id, mailbox)
      end

      private

      attr_reader :adapter, :id
    end
  end
end
