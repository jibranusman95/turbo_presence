# frozen_string_literal: true

require "spec_helper"

RSpec.describe TurboPresence::Color do
  describe ".for_user" do
    it "returns a hex color" do
      expect(described_class.for_user(1)).to match(/\A#[0-9A-F]{6}\z/i)
    end

    it "is deterministic — same user always gets same color" do
      expect(described_class.for_user(7)).to eq(described_class.for_user(7))
    end

    it "cycles through palette for different user ids" do
      colors = (0..7).map { |i| described_class.for_user(i) }
      expect(colors.uniq.size).to eq(8)
    end

    it "wraps around for user ids beyond palette size" do
      expect(described_class.for_user(0)).to eq(described_class.for_user(8))
    end
  end
end
