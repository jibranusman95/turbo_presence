# frozen_string_literal: true

require "openssl"
require "base64"
require "json"

module TurboPresence
  class RoomToken
    class InvalidToken < StandardError; end

    class << self
      def generate(record)
        payload = { m: record.class.name, i: record.id.to_s }
        json    = JSON.generate(payload)
        sig     = sign(json)
        Base64.urlsafe_encode64("#{json}.#{sig}", padding: false)
      end

      def verify!(token)
        raw            = Base64.urlsafe_decode64(token).force_encoding("UTF-8")
        last_dot       = raw.rindex(".")
        raise InvalidToken, "malformed token" unless last_dot

        json = raw[0, last_dot]
        sig  = raw[(last_dot + 1)..]

        raise InvalidToken, "invalid signature" unless secure_compare(sign(json), sig)

        payload = JSON.parse(json)
        raise InvalidToken, "malformed payload" unless payload["m"] && payload["i"]

        [payload["m"], payload["i"]]
      rescue ArgumentError, JSON::ParserError
        raise InvalidToken, "invalid token"
      end

      private

      def sign(data)
        secret = Rails.application.secret_key_base[0, 32]
        OpenSSL::HMAC.hexdigest("SHA256", secret, data)
      end

      def secure_compare(a, b)
        return false unless a.bytesize == b.bytesize

        ActiveSupport::SecurityUtils.secure_compare(a, b)
      end
    end
  end
end
