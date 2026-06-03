# frozen_string_literal: true

require "spec_helper"

RSpec.describe TurboPresence::RoomToken do
  let(:record) do
    double("Document", class: double(name: "Document"), id: 42)
  end

  before do
    # stub Rails.application.secret_key_base
    rails_app = double("app", secret_key_base: "a" * 64)
    stub_const("Rails", double("Rails", application: rails_app))
    stub_const("ActiveSupport::SecurityUtils", Module.new do
      def self.secure_compare(a, b)
        a == b
      end
    end)
  end

  describe ".generate and .verify!" do
    it "round-trips correctly" do
      token = described_class.generate(record)
      model_name, record_id = described_class.verify!(token)
      expect(model_name).to eq("Document")
      expect(record_id).to eq("42")
    end

    it "raises InvalidToken for a tampered token" do
      token = described_class.generate(record)
      tampered = "#{token[0..-5]}XXXX"
      expect { described_class.verify!(tampered) }.to raise_error(described_class::InvalidToken)
    end

    it "raises InvalidToken for a random string" do
      expect { described_class.verify!("notavalidtoken") }.to raise_error(described_class::InvalidToken)
    end
  end
end
