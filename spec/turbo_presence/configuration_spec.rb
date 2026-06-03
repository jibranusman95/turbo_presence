# frozen_string_literal: true

require "spec_helper"

RSpec.describe TurboPresence::Configuration do
  subject(:config) { described_class.new }

  it "has sensible defaults" do
    expect(config.presence_ttl).to eq(60)
    expect(config.cursor_throttle_ms).to eq(50)
  end

  it "reads REDIS_URL from environment" do
    allow(ENV).to receive(:[]).with("REDIS_URL").and_return("redis://localhost:6379/9")
    cfg = described_class.new
    expect(cfg.redis_url).to eq("redis://localhost:6379/9")
  end

  describe "#identify_user" do
    it "stores a custom block" do
      config.identify_user { |u| { id: u[:id], name: u[:name] } }
      result = config.user_identifier.call({ id: 42, name: "Alice" })
      expect(result).to eq({ id: 42, name: "Alice" })
    end
  end
end
