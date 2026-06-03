# frozen_string_literal: true

require_relative "turbo_presence/version"
require_relative "turbo_presence/configuration"
require_relative "turbo_presence/color"
require_relative "turbo_presence/room_token"
require_relative "turbo_presence/presence_store"
require_relative "turbo_presence/view_helper"
require_relative "turbo_presence/railtie" if defined?(Rails::Railtie)

module TurboPresence
  class Error < StandardError; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end

    def store
      @store ||= initialize_store!
    end

    def initialize_store!
      redis = build_redis
      @store = PresenceStore.new(redis: redis, ttl: configuration.presence_ttl)
    end

    def identify_current_user(user)
      configuration.user_identifier.call(user).dup
    end

    def auto_color(user_id)
      Color.for_user(user_id)
    end

    private

    def build_redis
      return nil unless configuration.redis_url

      require "redis"
      Redis.new(url: configuration.redis_url)
    rescue LoadError
      nil
    end
  end
end
