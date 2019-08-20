require "test_helper"
require "actionmailbox/imap"
require "minitest/mock"

class ActionMailbox::IMAP::Base::Test < ActiveSupport::TestCase
  test ".authenticate will call adapter authenticate" do
    mock = Minitest::Mock.new
    mock.expect :authenticate, nil, [username: "fake@email.com", password: "password"]

    imap = ActionMailbox::IMAP::Base.new(adapter: mock)

    imap.authenticate(username: "fake@email.com", password: "password")
    mock.verify
  end

  test ".select_mailbox will call adapter select_mailbox" do
    mock = Minitest::Mock.new
    mock.expect :select_mailbox, nil, ["INBOX"]

    imap = ActionMailbox::IMAP::Base.new(adapter: mock)

    imap.select_mailbox("INBOX")
    mock.verify
  end

  test ".select_mailbox returns a Mailbox successfully" do
    mock = Minitest::Mock.new
    mock.expect :select_mailbox, true, ["INBOX"]

    imap = ActionMailbox::IMAP::Base.new(adapter: mock)
    mailbox = imap.select_mailbox("INBOX")

    assert_instance_of(ActionMailbox::IMAP::Mailbox, mailbox)
    mock.verify
  end

  test ".select_mailbox returns false when adapter returns false" do
    mock = Minitest::Mock.new
    mock.expect :select_mailbox, false, ["INBOX"]

    imap = ActionMailbox::IMAP::Base.new(adapter: mock)
    mailbox = imap.select_mailbox("INBOX")

    assert !mailbox
    mock.verify
  end

  test "it will call adapter disconnect" do
    mock = Minitest::Mock.new
    mock.expect :disconnect, nil

    imap = ActionMailbox::IMAP::Base.new(adapter: mock)

    imap.disconnect
    mock.verify
  end
end
