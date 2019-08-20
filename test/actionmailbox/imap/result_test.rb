require "test_helper"
require "actionmailbox/imap/result"
require "minitest/mock"

class ActionMailbox::IMAP::Result::Test < ActiveSupport::TestCase
  test "returns a successful result" do
    result = ActionMailbox::IMAP::Result.success(works: true)

    assert result.success?
    assert result.works
    assert result.errors.empty?
  end

  test "returns a failure result" do
    result = ActionMailbox::IMAP::Result.failure(["Did not work"])

    assert !result.success?
    assert result.errors.include? "Did not work"
  end

  test "accepts a string as a failure" do
    result = ActionMailbox::IMAP::Result.failure("Did not work")

    assert !result.success?
    assert result.errors.include? "Did not work"
  end
end
