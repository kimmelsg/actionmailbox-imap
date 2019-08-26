module Imap
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path("templates", __dir__)

    def copy_imap_config_file
      copy_file "config.yml", "config/actionmailbox_imap.yaml"
    end
  end
end
