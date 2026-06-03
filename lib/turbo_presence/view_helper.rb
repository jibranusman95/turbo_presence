# frozen_string_literal: true

module TurboPresence
  module ViewHelper
    def turbo_presence_for(record, cursors: true, typing: true, class: nil, &block)
      token        = RoomToken.generate(record)
      identity     = TurboPresence.identify_current_user(current_user)
      identity[:color] ||= Color.for_user(identity[:id])
      css_class    = binding.local_variable_get(:class)

      tag.div(
        data: {
          controller:                    "turbo-presence",
          turbo_presence_room_token:     token,
          turbo_presence_identity:       identity.to_json,
          turbo_presence_cursors_value:  cursors,
          turbo_presence_typing_value:   typing,
          turbo_presence_throttle_value: TurboPresence.configuration.cursor_throttle_ms
        },
        class: ["turbo-presence", css_class].compact.join(" ")
      )
    end
  end
end
