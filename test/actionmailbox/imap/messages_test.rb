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
end
