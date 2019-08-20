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
          imap.expunge
          imap.disconnect
        end

        def messages_not_deleted
          imap.search(["NOT", "DELETED"])
        end

        def delete_message(id)
          imap.store(id, "+FLAGS", [:Deleted])
        end

        def fetch_message_attr(id, attr)
          imap.fetch(id, attr).first.attr[attr]
        end

        private

        attr_reader :imap
      end
    end
  end
end
