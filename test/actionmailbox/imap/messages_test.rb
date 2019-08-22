require "test_helper"
require "actionmailbox/imap"
require "minitest/mock"

class ActionMailbox::IMAP::Messages::Test < ActiveSupport::TestCase
  test ".take returns Messages" do
    fake_adapter = MiniTest::Mock.new

    messages = ActionMailbox::IMAP::Messages.new(adapter: fake_adapter, message_ids: [1, 2, 3, 4])
    result = messages.take(2)

    assert_instance_of(ActionMailbox::IMAP::Messages, result)
  end

  test ".take returns the right number of messages" do
    fake_adapter = MiniTest::Mock.new
    messages = ActionMailbox::IMAP::Messages.new(adapter: fake_adapter, message_ids: [1, 2, 3, 4])
    result = messages.take(2)

    assert result.length == 2
  end

  test ".length returns the count of messages" do
    fake_adapter = MiniTest::Mock.new

    messages = ActionMailbox::IMAP::Messages.new(adapter: fake_adapter, message_ids: [1, 2, 3, 4])
    result = messages.length

    assert result == 4
  end

  test ".each iterates over each ID yeilding a message" do
    fake_adapter = MiniTest::Mock.new

    messages = ActionMailbox::IMAP::Messages.new(adapter: fake_adapter, message_ids: [1, 2, 3, 4])

    count = 0
    messages.each do |message|
      assert_instance_of(ActionMailbox::IMAP::Message, message)
      count += 1
    end

    assert count == 4
  end

  test ".mark_read marks all messages as read" do
    fake_adapter = MiniTest::Mock.new

    messages = ActionMailbox::IMAP::Messages.new(adapter: fake_adapter, message_ids: [1, 2, 3, 4])

    [1, 2, 3, 4].each do |id|
      fake_adapter.expect :mark_message_seen, nil, [id]
    end

    messages.mark_read

    fake_adapter.verify
  end

  test ".mark_unread marks all messages as read" do
    fake_adapter = MiniTest::Mock.new

    messages = ActionMailbox::IMAP::Messages.new(adapter: fake_adapter, message_ids: [1, 2, 3, 4])

    [1, 2, 3, 4].each do |id|
      fake_adapter.expect :mark_message_unseen, nil, [id]
    end

    messages.mark_unread

    fake_adapter.verify
  end
end
