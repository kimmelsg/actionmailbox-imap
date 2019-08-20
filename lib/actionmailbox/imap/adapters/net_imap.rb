require "net/imap"

module ActionMailbox
  module IMAP
    module Adapters
      class NetImap
        def initialize(server:, port: 993, usessl: true)
          @imap = Net::IMAP.new(server, port, usessl)
        end

        def login(username:, password:)
          imap.login(username, password)
        end

        def select_mailbox(mailbox)
          imap.select(mailbox)
        end

        def disconnect
          # @TODO imap.expunge for deleted messages?
          imap.disconnect
        end

        def messages_not_deleted
          imap.search(["NOT", "DELETED"])
        end

        def delete_message(id)
          move_message_to(id, "TRASH")
        end

        def move_message_to(id, mailbox)
          imap.copy(id, mailbox)
          imap.store(id, "+FLAGS", ["DELETED"])
        end

        # @TODO test method
        def fetch_message_attr(id, attr)
          imap.fetch(id, attr).first.attr[attr]
        end

        private

        attr_reader :imap
      end
    end
  end
end
