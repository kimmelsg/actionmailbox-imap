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

        def messages
          imap.search(["NOT", "DELETED", "NOT", "SEEN"])
        end

        def delete_message(id)
          imap.store(id, "+FLAGS", [:Deleted])
        end

        def mark_message_seen(id)
          imap.store(id, "+FLAGS", [:Seen])
        end

        def mark_message_unseen(id)
          imap.store(id, "-FLAGS", [:Seen])
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
