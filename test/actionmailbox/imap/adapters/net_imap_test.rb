require "test_helper"
require "minitest/stub_const"
require "minitest/mock"
require "actionmailbox/imap/adapters/net_imap"
require "net/imap"

class ActionMailbox::IMAP::Adapters::NetImap::Test < ActiveSupport::TestCase
  test "it creates a Net::IMAP instance" do
    net_imap = MiniTest::Mock.new
    net_imap.expect :new, "something", ["some.server.com", 993, true]

    Net.stub_const :IMAP, net_imap do
      ActionMailbox::IMAP::Adapters::NetImap.new(
        server: "some.server.com",
        port: 993,
        usessl: true
      )

      net_imap.verify
    end
  end

  test ".login calls login on Net::IMAP" do
    net_imap = MiniTest::Mock.new
    net_imap.expect :new, net_imap, ["some.server.com", 993, true]
    net_imap.expect :login, nil, ["some@email.com", "password"]

    Net.stub_const :IMAP, net_imap do
      fake_adapter = ActionMailbox::IMAP::Adapters::NetImap.new(
        server: "some.server.com",
        port: 993,
        usessl: true
      )

      fake_adapter.login(username: "some@email.com", password: "password")

      net_imap.verify
    end
  end

  test ".select_mailbox calls select on Net::IMAP" do
    net_imap = MiniTest::Mock.new
    net_imap.expect :new, net_imap, ["some.server.com", 993, true]
    net_imap.expect :select, nil, ["INBOX"]

    Net.stub_const :IMAP, net_imap do
      fake_adapter = ActionMailbox::IMAP::Adapters::NetImap.new(
        server: "some.server.com",
        port: 993,
        usessl: true
      )

      fake_adapter.select_mailbox("INBOX")

      net_imap.verify
    end
  end

  test ".disconnect calls disconnect on Net::IMAP successfully" do
    net_imap = MiniTest::Mock.new
    net_imap.expect :new, net_imap, ["some.server.com", 993, true]
    net_imap.expect :expunge, nil
    net_imap.expect :disconnect, nil

    Net.stub_const :IMAP, net_imap do
      fake_adapter = ActionMailbox::IMAP::Adapters::NetImap.new(
        server: "some.server.com",
        port: 993,
        usessl: true
      )

      fake_adapter.disconnect

      net_imap.verify
    end
  end

  test ".messages calls search successfully" do
    net_imap = MiniTest::Mock.new
    net_imap.expect :new, net_imap, ["some.server.com", 993, true]
    net_imap.expect :search, [1, 2], [["NOT", "DELETED", "NOT", "SEEN"]]

    Net.stub_const :IMAP, net_imap do
      fake_adapter = ActionMailbox::IMAP::Adapters::NetImap.new(
        server: "some.server.com",
        port: 993,
        usessl: true
      )

      fake_adapter.messages

      net_imap.verify
    end
  end

  test ".delete_message deletes a message successfully" do
    net_imap = MiniTest::Mock.new
    net_imap.expect :new, net_imap, ["some.server.com", 993, true]
    net_imap.expect :store, nil, [1, "+FLAGS", [:Deleted]]

    Net.stub_const :IMAP, net_imap do
      fake_adapter = ActionMailbox::IMAP::Adapters::NetImap.new(
        server: "some.server.com",
        port: 993,
        usessl: true
      )

      fake_adapter.delete_message(1)

      net_imap.verify
    end
  end

  test ".mark_message_seen marks a message as seen" do
    net_imap = MiniTest::Mock.new
    net_imap.expect :new, net_imap, ["some.server.com", 993, true]
    net_imap.expect :store, nil, [1, "+FLAGS", [:Seen]]

    Net.stub_const :IMAP, net_imap do
      fake_adapter = ActionMailbox::IMAP::Adapters::NetImap.new(
        server: "some.server.com",
        port: 993,
        usessl: true
      )

      fake_adapter.mark_message_seen(1)

      net_imap.verify
    end
  end

  test ".mark_message_unseen marks a message as seen" do
    net_imap = MiniTest::Mock.new
    net_imap.expect :new, net_imap, ["some.server.com", 993, true]
    net_imap.expect :store, nil, [1, "-FLAGS", [:Seen]]

    Net.stub_const :IMAP, net_imap do
      fake_adapter = ActionMailbox::IMAP::Adapters::NetImap.new(
        server: "some.server.com",
        port: 993,
        usessl: true
      )

      fake_adapter.mark_message_unseen(1)

      net_imap.verify
    end
  end

  test ".fetch_message_attr returns attribute successfully" do
    net_imap = MiniTest::Mock.new
    net_imap.expect :new, net_imap, ["some.server.com", 993, true]

    imap_message = MiniTest::Mock.new
    def imap_message.attr
      {"RFC822" => "success"}
    end

    net_imap.expect :fetch, [imap_message], [1, "RFC822"]

    Net.stub_const :IMAP, net_imap do
      fake_adapter = ActionMailbox::IMAP::Adapters::NetImap.new(
        server: "some.server.com",
        port: 993,
        usessl: true
      )

      result = fake_adapter.fetch_message_attr(1, "RFC822")

      assert result == "success"
      net_imap.verify
    end
  end
end
