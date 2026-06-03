# frozen_string_literal: true

require "spec_helper"

RSpec.describe TurboPresence::PresenceStore do
  subject(:store) { described_class.new(redis: nil, ttl: 60) }

  let(:room)     { "Document:1" }
  let(:identity) { { id: "1", name: "Alice", color: "#E63946" } }

  describe "#join and #all" do
    it "adds a user to a room" do
      store.join(room, "1", identity)
      expect(store.all(room)).to eq({ "1" => identity })
    end

    it "supports multiple users in the same room" do
      bob = { id: "2", name: "Bob", color: "#2196F3" }
      store.join(room, "1", identity)
      store.join(room, "2", bob)
      expect(store.all(room).keys).to contain_exactly("1", "2")
    end

    it "returns empty hash for unknown room" do
      expect(store.all("Document:999")).to eq({})
    end
  end

  describe "#leave" do
    it "removes a user from the room" do
      store.join(room, "1", identity)
      store.leave(room, "1")
      expect(store.all(room)).to eq({})
    end

    it "is a no-op for unknown user" do
      expect { store.leave(room, "999") }.not_to raise_error
    end
  end

  describe "#update_cursor" do
    it "updates cursor coordinates for a user" do
      store.join(room, "1", identity)
      store.update_cursor(room, "1", x: 0.5, y: 0.3)
      entry = store.all(room)["1"]
      expect(entry[:cursor_x]).to eq(0.5)
      expect(entry[:cursor_y]).to eq(0.3)
    end

    it "is a no-op if user is not in room" do
      expect { store.update_cursor(room, "999", x: 0.5, y: 0.3) }.not_to raise_error
    end
  end

  describe "thread safety" do
    it "handles concurrent joins without raising" do
      threads = 20.times.map do |i|
        Thread.new { store.join(room, i.to_s, { id: i.to_s, name: "User#{i}" }) }
      end
      threads.each(&:join)
      expect(store.all(room).size).to eq(20)
    end
  end
end
