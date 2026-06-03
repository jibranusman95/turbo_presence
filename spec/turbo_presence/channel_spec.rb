# frozen_string_literal: true

require "spec_helper"
require "ostruct"

# Minimal Action Cable stubs so we can test the channel without a full Rails app
module ActionCable
  module Channel
    class Base
      attr_reader :params

      def initialize(params = {})
        @params = params
      end

      def stream_from(_stream); end
      def reject; end
      def rejected?; false; end
    end
  end

  module Server
    def self.broadcast(stream, payload); end
  end

  def self.server
    Server
  end
end

require_relative "../../app/channels/turbo_presence_channel"

RSpec.describe TurboPresenceChannel do
  let(:alice_identity) { { id: "1", name: "Alice", color: "#E63946" } }
  let(:record)         { OpenStruct.new(class: OpenStruct.new(name: "Document"), id: 42) }

  before do
    rails_app = double("app", secret_key_base: "a" * 64)
    stub_const("Rails", double("Rails", application: rails_app))
    stub_const("ActiveSupport::SecurityUtils", Module.new do
      def self.secure_compare(a, b) = a == b
    end)
  end

  def valid_token
    TurboPresence::RoomToken.generate(record)
  end

  def build_channel(token: valid_token, identity: alice_identity)
    described_class.new(
      room_token: token,
      identity:   identity.to_json
    )
  end

  describe "#subscribed" do
    it "streams from the presence room" do
      channel = build_channel
      expect(channel).to receive(:stream_from).with("turbo_presence:Document:42")
      channel.subscribed
    end

    it "adds the user to the presence store" do
      channel = build_channel
      allow(channel).to receive(:stream_from)
      allow(ActionCable.server).to receive(:broadcast)
      channel.subscribed
      expect(TurboPresence.store.all("Document:42")).to have_key("1")
    end

    it "rejects on invalid token" do
      channel = build_channel(token: "invalid_token")
      expect(channel).to receive(:reject)
      channel.subscribed
    end

    it "broadcasts presence on join" do
      channel = build_channel
      allow(channel).to receive(:stream_from)
      expect(ActionCable.server).to receive(:broadcast).with(
        "turbo_presence:Document:42",
        hash_including(type: "presence")
      )
      channel.subscribed
    end
  end

  describe "#unsubscribed" do
    it "removes user from presence store" do
      channel = build_channel
      allow(channel).to receive(:stream_from)
      allow(ActionCable.server).to receive(:broadcast)
      channel.subscribed
      channel.unsubscribed
      expect(TurboPresence.store.all("Document:42")).not_to have_key("1")
    end

    it "broadcasts presence after leaving" do
      channel = build_channel
      allow(channel).to receive(:stream_from)
      allow(ActionCable.server).to receive(:broadcast)
      channel.subscribed

      expect(ActionCable.server).to receive(:broadcast).with(
        "turbo_presence:Document:42",
        hash_including(type: "presence")
      )
      channel.unsubscribed
    end

    it "is a no-op if never subscribed" do
      channel = build_channel(token: "invalid_token")
      channel.subscribed
      expect { channel.unsubscribed }.not_to raise_error
    end
  end

  describe "#cursor" do
    it "broadcasts clamped cursor coordinates" do
      channel = build_channel
      allow(channel).to receive(:stream_from)
      allow(ActionCable.server).to receive(:broadcast).with(anything, hash_including(type: "presence"))
      channel.subscribed

      expect(ActionCable.server).to receive(:broadcast).with(
        "turbo_presence:Document:42",
        { type: "cursor", user_id: "1", x: 0.5, y: 0.3 }
      )
      channel.cursor("x" => 0.5, "y" => 0.3)
    end

    it "clamps coordinates to 0.0–1.0" do
      channel = build_channel
      allow(channel).to receive(:stream_from)
      allow(ActionCable.server).to receive(:broadcast).with(anything, hash_including(type: "presence"))
      channel.subscribed

      expect(ActionCable.server).to receive(:broadcast).with(
        "turbo_presence:Document:42",
        { type: "cursor", user_id: "1", x: 1.0, y: 0.0 }
      )
      channel.cursor("x" => 5.0, "y" => -2.0)
    end
  end

  describe "#typing" do
    it "broadcasts typing active" do
      channel = build_channel
      allow(channel).to receive(:stream_from)
      allow(ActionCable.server).to receive(:broadcast).with(anything, hash_including(type: "presence"))
      channel.subscribed

      expect(ActionCable.server).to receive(:broadcast).with(
        "turbo_presence:Document:42",
        { type: "typing", user_id: "1", name: "Alice", active: true }
      )
      channel.typing("active" => true)
    end
  end

  describe "#heartbeat" do
    it "touches the presence store entry" do
      channel = build_channel
      allow(channel).to receive(:stream_from)
      allow(ActionCable.server).to receive(:broadcast)
      channel.subscribed

      expect(TurboPresence.store).to receive(:touch).with("Document:42", "1")
      channel.heartbeat
    end
  end
end
