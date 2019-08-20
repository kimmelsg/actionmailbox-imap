module ActionMailbox
  module IMAP
    class Message
      RFC822 = "RFC822".freeze

      def initialize(adapter:, id:)
        @adapter = adapter
        @id = id
      end

      def get_id
        id
      end

      def rfc822
        # @TODO create adapter method
        adapter.fetch_attr(id, RFC822).tap do |result|
          return false unless result # @TODO use Result object instead of false
        end
      end

      def delete
        adapter.delete_message(id).tap do |result|
          return false unless result # @TODO use Result object instead of false
        end
      end

      def move_to(mailbox)
        adapter.move_message_to(id, mailbox).tap do |result|
          return false unless result # @TODO use Result object instead of false
        end
      end

      private

      attr_reader :adapter, :id
    end
  end
end
