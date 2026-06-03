# frozen_string_literal: true

module TurboPresence
  class Configuration
    attr_accessor :redis_url, :presence_ttl, :cursor_throttle_ms
    attr_reader :user_identifier

    def initialize
      @redis_url         = ENV["REDIS_URL"]
      @presence_ttl      = 60
      @cursor_throttle_ms = 50
      @user_identifier   = ->(user) { { id: user.id, name: user.to_s } }
    end

    def identify_user(&block)
      @user_identifier = block
    end
  end
end
