require "test_helper"
require "actionmailbox/imap/message"
require "minitest/mock"

class ActionMailbox::IMAP::Message::Test < ActiveSupport::TestCase
  test ".rfc822 fetches the RFC822 from the adapter" do
    fake_adapter = MiniTest::Mock.new
    fake_adapter.expect :fetch_message_attr, nil, [1, "RFC822"]

    message = ActionMailbox::IMAP::Message.new(adapter: fake_adapter, id: 1)
    message.rfc822

    fake_adapter.verify
  end

  test ".rfc822 returns false when it fails to fetch the rfc822" do
    fake_adapter = MiniTest::Mock.new
    fake_adapter.expect :fetch_message_attr, false, [1, "RFC822"]

    message = ActionMailbox::IMAP::Message.new(adapter: fake_adapter, id: 1)
    result = message.rfc822

    assert !result
    fake_adapter.verify
  end

  test ".delete calls adapter delete_message successfully" do
    fake_adapter = MiniTest::Mock.new
    fake_adapter.expect :delete_message, true, [1]

    message = ActionMailbox::IMAP::Message.new(adapter: fake_adapter, id: 1)
    result = message.delete

    assert result
    fake_adapter.verify
  end

  test ".delete returns false when the adapter returns false" do
    fake_adapter = MiniTest::Mock.new
    fake_adapter.expect :delete_message, false, [1]

    message = ActionMailbox::IMAP::Message.new(adapter: fake_adapter, id: 1)
    result = message.delete

    assert !result
    fake_adapter.verify
  end
end
