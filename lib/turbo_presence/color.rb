# frozen_string_literal: true

module TurboPresence
  module Color
    PALETTE = %w[
      #E63946 #2196F3 #4CAF50 #FF9800 #9C27B0 #00BCD4 #FF5722 #607D8B
    ].freeze

    def self.for_user(user_id)
      PALETTE[user_id.to_i % PALETTE.size]
    end
  end
end
