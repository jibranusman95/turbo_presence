# frozen_string_literal: true

module TurboPresence
  class PresenceStore
    def initialize(redis: nil, ttl: 60)
      @redis  = redis
      @ttl    = ttl
      @memory = {}
      @mutex  = Mutex.new
    end

    # Returns hash of { user_id => identity_hash } for a room
    def all(room)
      if @redis
        entries = @redis.hgetall(redis_key(room))
        entries.transform_values { |v| JSON.parse(v, symbolize_names: true) }
      else
        @mutex.synchronize { (@memory[room] || {}).dup }
      end
    end

    def join(room, user_id, identity)
      if @redis
        @redis.hset(redis_key(room), user_id.to_s, identity.to_json)
        @redis.expire(redis_key(room), @ttl)
      else
        @mutex.synchronize do
          @memory[room] ||= {}
          @memory[room][user_id.to_s] = identity
        end
      end
    end

    def leave(room, user_id)
      if @redis
        @redis.hdel(redis_key(room), user_id.to_s)
      else
        @mutex.synchronize { @memory[room]&.delete(user_id.to_s) }
      end
    end

    def update_cursor(room, user_id, x:, y:)
      if @redis
        raw = @redis.hget(redis_key(room), user_id.to_s)
        return unless raw

        identity = JSON.parse(raw, symbolize_names: true)
        identity[:cursor_x] = x
        identity[:cursor_y] = y
        @redis.hset(redis_key(room), user_id.to_s, identity.to_json)
        @redis.expire(redis_key(room), @ttl)
      else
        @mutex.synchronize do
          entry = @memory.dig(room, user_id.to_s)
          return unless entry

          entry[:cursor_x] = x
          entry[:cursor_y] = y
        end
      end
    end

    def touch(room, _user_id)
      @redis&.expire(redis_key(room), @ttl)
    end

    private

    def redis_key(room)
      "turbo_presence:#{room}"
    end
  end
end
