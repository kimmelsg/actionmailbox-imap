require "test_helper"
require "actionmailbox/imap"
require "minitest/mock"

class ActionMailbox::IMAP::Mailbox::Test < ActiveSupport::TestCase
  test ".not_deleted returns Messages successfully" do
    fake_adapter = MiniTest::Mock.new
    fake_adapter.expect :messages_not_deleted, [1, 2]

    mailbox = ActionMailbox::IMAP::Mailbox.new(adapter: fake_adapter, mailbox: "INBOX")
    result = mailbox.not_deleted

    assert result
    assert_instance_of(ActionMailbox::IMAP::Messages, result)
    fake_adapter.verify
  end
end