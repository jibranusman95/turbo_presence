# frozen_string_literal: true

require_relative "lib/turbo_presence/version"

Gem::Specification.new do |spec|
  spec.name          = "turbo_presence"
  spec.version       = TurboPresence::VERSION
  spec.authors       = ["Jibran Usman"]
  spec.email         = ["jibran.usman@hotmail.com"]

  spec.summary       = "Figma-style live cursors, avatar stacks, and typing indicators for Rails. One line."
  spec.description   = "turbo_presence spins up real-time multi-user presence in any Rails + Hotwire app. " \
                       "Drop <%= turbo_presence_for(@document) %> into any view and get live cursors, " \
                       "avatar stacks, and typing indicators — built on Action Cable, zero JavaScript required."
  spec.homepage      = "https://github.com/jibranusman95/turbo_presence"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/jibranusman95/turbo_presence"
  spec.metadata["changelog_uri"]   = "https://github.com/jibranusman95/turbo_presence/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) || f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "turbo-rails"
end
