# frozen_string_literal: true

require "spec_helper"

RSpec.describe TurboPresence do
  describe ".configure" do
    it "yields the configuration object" do
      described_class.configure do |config|
        config.presence_ttl = 120
      end
      expect(described_class.configuration.presence_ttl).to eq(120)
    end

    it "persists configuration across calls" do
      described_class.configure { |c| c.cursor_throttle_ms = 100 }
      expect(described_class.configuration.cursor_throttle_ms).to eq(100)
    end
  end

  describe ".configuration" do
    it "returns a Configuration instance" do
      expect(described_class.configuration).to be_a(TurboPresence::Configuration)
    end

    it "returns the same instance on repeated calls" do
      expect(described_class.configuration).to be(described_class.configuration)
    end
  end

  describe ".identify_current_user" do
    it "calls the configured identifier block" do
      described_class.configure do |config|
        config.identify_user { |u| { id: u[:id], name: u[:name] } }
      end

      result = described_class.identify_current_user({ id: 1, name: "Alice" })
      expect(result).to eq({ id: 1, name: "Alice" })
    end

    it "returns a dup so callers can mutate without affecting the original" do
      described_class.configure do |config|
        config.identify_user { |u| { id: u[:id], name: u[:name] } }
      end

      user   = { id: 1, name: "Alice" }
      result = described_class.identify_current_user(user)
      result[:color] = "#E63946"
      expect(described_class.identify_current_user(user)).not_to have_key(:color)
    end
  end

  describe ".auto_color" do
    it "delegates to Color.for_user" do
      expect(TurboPresence::Color).to receive(:for_user).with(5).and_return("#E63946")
      described_class.auto_color(5)
    end
  end

  describe ".store" do
    it "returns a PresenceStore instance" do
      expect(described_class.store).to be_a(TurboPresence::PresenceStore)
    end

    it "returns the same instance on repeated calls" do
      expect(described_class.store).to be(described_class.store)
    end
  end

  describe ".initialize_store!" do
    it "resets the store instance" do
      old_store = described_class.store
      described_class.initialize_store!
      expect(described_class.store).not_to be(old_store)
    end
  end
end
