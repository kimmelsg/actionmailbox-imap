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

  test ".login returns false when a error is thrown" do
    net_imap = MiniTest::Mock.new
    net_imap.expect :new, net_imap, ["some.server.com", 993, true]
    def net_imap.login(username:, password:)
      throw Exception
    end

    Net.stub_const :IMAP, net_imap do
      fake_adapter = ActionMailbox::IMAP::Adapters::NetImap.new(
        server: "some.server.com",
        port: 993,
        usessl: true
      )

      assert !fake_adapter.login(username: "some@email.com", password: "password")

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

  test ".select_mailbox returns false with Exception" do
    net_imap = MiniTest::Mock.new
    net_imap.expect :new, net_imap, ["some.server.com", 993, true]
    def net_imap.select
      throw Exception
    end

    Net.stub_const :IMAP, net_imap do
      fake_adapter = ActionMailbox::IMAP::Adapters::NetImap.new(
        server: "some.server.com",
        port: 993,
        usessl: true
      )

      assert !fake_adapter.select_mailbox("INBOX")

      net_imap.verify
    end
  end

  test ".disconnect calls disconnect on Net::IMAP successfully" do
    net_imap = MiniTest::Mock.new
    net_imap.expect :new, net_imap, ["some.server.com", 993, true]
    net_imap.expect :disconnect, nil

    Net.stub_const :IMAP, net_imap do
      fake_adapter = ActionMailbox::IMAP::Adapters::NetImap.new(
        server: "some.server.com",
        port: 993,
        usessl: true
      )

      result = fake_adapter.disconnect

      assert result
      net_imap.verify
    end
  end

  test ".disconnect calls disconnect returns false when it fails" do
    net_imap = MiniTest::Mock.new
    net_imap.expect :new, net_imap, ["some.server.com", 993, true]
    def net_imap.disconnect
      throw Exception
    end

    Net.stub_const :IMAP, net_imap do
      fake_adapter = ActionMailbox::IMAP::Adapters::NetImap.new(
        server: "some.server.com",
        port: 993,
        usessl: true
      )

      result = fake_adapter.disconnect

      assert !result
      net_imap.verify
    end
  end

  test ".message_not_deleted calls search successfully" do
    net_imap = MiniTest::Mock.new
    net_imap.expect :new, net_imap, ["some.server.com", 993, true]
    net_imap.expect :search, [1, 2], [["NOT", "DELETED"]]

    Net.stub_const :IMAP, net_imap do
      fake_adapter = ActionMailbox::IMAP::Adapters::NetImap.new(
        server: "some.server.com",
        port: 993,
        usessl: true
      )

      result = fake_adapter.messages_not_deleted

      assert result
      net_imap.verify
    end
  end

  test ".message_not_deleted returns false when failed" do
    net_imap = MiniTest::Mock.new
    net_imap.expect :new, net_imap, ["some.server.com", 993, true]
    def net_imap.search(params)
      throw Exception
    end

    Net.stub_const :IMAP, net_imap do
      fake_adapter = ActionMailbox::IMAP::Adapters::NetImap.new(
        server: "some.server.com",
        port: 993,
        usessl: true
      )

      result = fake_adapter.messages_not_deleted

      assert !result
      net_imap.verify
    end
  end

  test ".delete_message deletes a message successfully" do
    net_imap = MiniTest::Mock.new
    net_imap.expect :new, net_imap, ["some.server.com", 993, true]
    net_imap.expect :copy, nil, [1, "TRASH"]
    net_imap.expect :store, nil, [1, "+FLAGS", ["DELETED"]]

    Net.stub_const :IMAP, net_imap do
      fake_adapter = ActionMailbox::IMAP::Adapters::NetImap.new(
        server: "some.server.com",
        port: 993,
        usessl: true
      )

      result = fake_adapter.delete_message(1)

      assert result
      net_imap.verify
    end
  end

  test ".delete_message returns false when it fails to delete a message" do
    net_imap = MiniTest::Mock.new
    net_imap.expect :new, net_imap, ["some.server.com", 993, true]
    def net_imap.copy(id, mailbox)
      throw Exception
    end

    Net.stub_const :IMAP, net_imap do
      fake_adapter = ActionMailbox::IMAP::Adapters::NetImap.new(
        server: "some.server.com",
        port: 993,
        usessl: true
      )

      result = fake_adapter.delete_message(1)

      assert !result
      net_imap.verify
    end
  end

  test ".move_message_to deletes a message successfully" do
    net_imap = MiniTest::Mock.new
    net_imap.expect :new, net_imap, ["some.server.com", 993, true]
    net_imap.expect :copy, nil, [1, "Saved"]
    net_imap.expect :store, nil, [1, "+FLAGS", ["DELETED"]]

    Net.stub_const :IMAP, net_imap do
      fake_adapter = ActionMailbox::IMAP::Adapters::NetImap.new(
        server: "some.server.com",
        port: 993,
        usessl: true
      )

      result = fake_adapter.move_message_to(1, "Saved")

      assert result
      net_imap.verify
    end
  end

  test ".move_message returns false when it fails to move a message" do
    net_imap = MiniTest::Mock.new
    net_imap.expect :new, net_imap, ["some.server.com", 993, true]
    def net_imap.copy(id, mailbox)
      throw Exception
    end

    Net.stub_const :IMAP, net_imap do
      fake_adapter = ActionMailbox::IMAP::Adapters::NetImap.new(
        server: "some.server.com",
        port: 993,
        usessl: true
      )

      result = fake_adapter.move_message_to(1, "Saved")

      assert !result
      net_imap.verify
    end
  end
end
