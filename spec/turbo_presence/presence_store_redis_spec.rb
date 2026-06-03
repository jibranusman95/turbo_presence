# frozen_string_literal: true

require "spec_helper"

RSpec.describe TurboPresence::PresenceStore do
  let(:redis)    { instance_double("Redis") }
  let(:store)    { described_class.new(redis: redis, ttl: 60) }
  let(:room)     { "Document:1" }
  let(:identity) { { id: "1", name: "Alice", color: "#E63946" } }

  describe "#join (Redis adapter)" do
    it "stores identity as JSON in Redis hash" do
      expect(redis).to receive(:hset).with("turbo_presence:#{room}", "1", identity.to_json)
      expect(redis).to receive(:expire).with("turbo_presence:#{room}", 60)
      store.join(room, "1", identity)
    end
  end

  describe "#all (Redis adapter)" do
    it "returns parsed identities from Redis" do
      allow(redis).to receive(:hgetall).with("turbo_presence:#{room}")
                                       .and_return({ "1" => identity.to_json })
      result = store.all(room)
      expect(result["1"][:name]).to eq("Alice")
    end

    it "returns empty hash when room has no entries" do
      allow(redis).to receive(:hgetall).and_return({})
      expect(store.all(room)).to eq({})
    end
  end

  describe "#leave (Redis adapter)" do
    it "removes user from Redis hash" do
      expect(redis).to receive(:hdel).with("turbo_presence:#{room}", "1")
      store.leave(room, "1")
    end
  end

  describe "#update_cursor (Redis adapter)" do
    it "updates cursor coordinates in Redis" do
      allow(redis).to receive(:hget).with("turbo_presence:#{room}", "1")
                                    .and_return(identity.to_json)
      expect(redis).to receive(:hset).with(
        "turbo_presence:#{room}", "1",
        satisfy { |v|
          parsed = JSON.parse(v)
          parsed["cursor_x"] == 0.5 && parsed["cursor_y"] == 0.3
        }
      )
      expect(redis).to receive(:expire).with("turbo_presence:#{room}", 60)
      store.update_cursor(room, "1", x: 0.5, y: 0.3)
    end

    it "is a no-op when user is not in room" do
      allow(redis).to receive(:hget).and_return(nil)
      expect(redis).not_to receive(:hset)
      store.update_cursor(room, "999", x: 0.5, y: 0.3)
    end
  end

  describe "#touch (Redis adapter)" do
    it "refreshes TTL on the room key" do
      expect(redis).to receive(:expire).with("turbo_presence:#{room}", 60)
      store.touch(room, "1")
    end
  end
end
