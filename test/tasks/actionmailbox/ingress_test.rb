require "test_helper"
require "actionmailbox/imap"
require "minitest/mock"
require "minitest/stub_const"
require "action_mailbox/relayer"

Rails.application.load_tasks

class ActionMailbox::IngressTest < ActiveSupport::TestCase
  test "it grabs messages and relays them to ActionMailbox successfully while deleting" do
    ingress_task = Rake::Task["action_mailbox:ingress:imap"]

    rails_mock = MiniTest::Mock.new
    rails_application_mock = MiniTest::Mock.new
    net_imap_mock = MiniTest::Mock.new

    ENV["URL"] = "http://localhost:3000/rails/action_mailbox/inbound_email"
    ENV["INGRESS_PASSWORD"] = "ingress_password"

    rails_mock.expect :application, rails_application_mock
    rails_application_mock.expect :config_for, {
      server: "smtp.email.com",
      port: 993,
      usessl: true,
      username: "some@email.com",
      password: "smtp_password",
      ingress_mailbox: "INBOX",
      take: 10,
    }, [:actionmailbox_imap]

    net_imap_mock.expect :new, net_imap_mock, [server: "smtp.email.com", port: 993, usessl: true]
    net_imap_mock.expect :login, nil, [username: "some@email.com", password: "smtp_password"]
    net_imap_mock.expect :select_mailbox, nil, ["INBOX"]

    fake_message_ids = [1, 2, 3]
    net_imap_mock.expect :messages, fake_message_ids
    fake_message_ids.each do |id|
      net_imap_mock.expect :mark_message_seen, nil, [id]
    end

    net_imap_mock.expect :fetch_message_attr, "message 1", [1, "RFC822"]
    net_imap_mock.expect :fetch_message_attr, "message 2", [2, "RFC822"]
    net_imap_mock.expect :fetch_message_attr, "message 3", [3, "RFC822"]

    action_mailbox_relayer_mock = MiniTest::Mock.new
    action_mailbox_relayer_mock.expect :new, action_mailbox_relayer_mock, [
      url: "http://localhost:3000/rails/action_mailbox/inbound_email",
      password: "ingress_password",
    ]

    action_mailbox_relayer_result_mock = MiniTest::Mock.new
    def action_mailbox_relayer_result_mock.tap
      yield Struct.new(:success?, keyword_init: true).new(success?: true)
    end

    action_mailbox_relayer_mock.expect :relay, action_mailbox_relayer_result_mock, ["message 1"]
    net_imap_mock.expect :delete_message, nil, [1]
    action_mailbox_relayer_mock.expect :relay, action_mailbox_relayer_result_mock, ["message 2"]
    net_imap_mock.expect :delete_message, nil, [2]
    action_mailbox_relayer_mock.expect :relay, action_mailbox_relayer_result_mock, ["message 3"]
    net_imap_mock.expect :delete_message, nil, [3]

    net_imap_mock.expect :disconnect, nil

    Object.stub_const :Rails, rails_mock do
      ActionMailbox::IMAP::Adapters.stub_const :NetImap, net_imap_mock do
        ActionMailbox.stub_const :Relayer, action_mailbox_relayer_mock do
          ingress_task.invoke
        end
      end
    end

    rails_mock.verify
    rails_application_mock.verify
    net_imap_mock.verify
    action_mailbox_relayer_mock.verify
  end

  test "it grabs messages and fails to relay them to ActionMailbox while not deleteing them" do
    ingress_task = Rake::Task["action_mailbox:ingress:imap"]

    rails_mock = MiniTest::Mock.new
    rails_application_mock = MiniTest::Mock.new
    net_imap_mock = MiniTest::Mock.new

    ENV["URL"] = "http://localhost:3000/rails/action_mailbox/inbound_email"
    ENV["INGRESS_PASSWORD"] = "ingress_password"

    rails_mock.expect :application, rails_application_mock
    rails_application_mock.expect :config_for, {
      server: "smtp.email.com",
      port: 993,
      usessl: true,
      username: "some@email.com",
      password: "smtp_password",
      ingress_mailbox: "INBOX",
      take: 10,
    }, [:actionmailbox_imap]

    net_imap_mock.expect :new, net_imap_mock, [server: "smtp.email.com", port: 993, usessl: true]
    net_imap_mock.expect :login, nil, [username: "some@email.com", password: "smtp_password"]
    net_imap_mock.expect :select_mailbox, nil, ["INBOX"]
    fake_message_ids = [1, 2, 3]
    net_imap_mock.expect :messages, fake_message_ids
    fake_message_ids.each do |id|
      net_imap_mock.expect :mark_message_seen, nil, [id]
    end

    net_imap_mock.expect :fetch_message_attr, "message 1", [1, "RFC822"]
    net_imap_mock.expect :fetch_message_attr, "message 2", [2, "RFC822"]
    net_imap_mock.expect :fetch_message_attr, "message 3", [3, "RFC822"]

    action_mailbox_relayer_mock = MiniTest::Mock.new
    action_mailbox_relayer_mock.expect :new, action_mailbox_relayer_mock, [
      url: "http://localhost:3000/rails/action_mailbox/inbound_email",
      password: "ingress_password",
    ]

    action_mailbox_relayer_result_mock = MiniTest::Mock.new
    def action_mailbox_relayer_result_mock.tap
      yield Struct.new(:success?, keyword_init: true).new(success?: false)
    end

    action_mailbox_relayer_mock.expect :relay, action_mailbox_relayer_result_mock, ["message 1"]
    net_imap_mock.expect :mark_message_unseen, nil, [1]
    action_mailbox_relayer_mock.expect :relay, action_mailbox_relayer_result_mock, ["message 2"]
    net_imap_mock.expect :mark_message_unseen, nil, [2]
    action_mailbox_relayer_mock.expect :relay, action_mailbox_relayer_result_mock, ["message 3"]
    net_imap_mock.expect :mark_message_unseen, nil, [3]

    net_imap_mock.expect :disconnect, nil

    Object.stub_const :Rails, rails_mock do
      ActionMailbox::IMAP::Adapters.stub_const :NetImap, net_imap_mock do
        ActionMailbox.stub_const :Relayer, action_mailbox_relayer_mock do
          ingress_task.execute
        end
      end
    end

    rails_mock.verify
    rails_application_mock.verify
    net_imap_mock.verify
    action_mailbox_relayer_mock.verify
  end
end
