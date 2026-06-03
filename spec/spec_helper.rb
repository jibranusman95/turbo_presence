# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
  minimum_coverage 75
  add_filter "/lib/turbo_presence/railtie.rb"
  add_filter "/lib/turbo_presence/view_helper.rb"
  add_filter "/app/"
end

require "turbo_presence"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.order = :random
  Kernel.srand config.seed

  config.before do
    TurboPresence.instance_variable_set(:@configuration, nil)
    TurboPresence.instance_variable_set(:@store, nil)
  end
end
