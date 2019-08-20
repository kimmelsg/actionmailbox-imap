$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "actionmailbox/imap/version"
# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name = "actionmailbox-imap"
  spec.version = Actionmailbox::Imap::VERSION
  spec.authors = ["Ethan Knowlton"]
  spec.email = ["eknowlton@gmail.com"]
  spec.homepage = "https://github.com/kimmelsg"
  spec.summary = "Relay IMAP messages to ActionMailbox"
  spec.description = "Relay IMAP messages to ActionMailbox"
  spec.license = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6.0.0.rc2"

  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "minitest-stub-const"
  spec.add_development_dependency "standard"
end
