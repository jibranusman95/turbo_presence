# frozen_string_literal: true

class TurboPresenceChannel < ActionCable::Channel::Base
  def subscribed
    token = params[:room_token]
    model_name, record_id = TurboPresence::RoomToken.verify!(token)

    @room     = "#{model_name}:#{record_id}"
    @identity = JSON.parse(params[:identity], symbolize_names: true)
    @user_id  = @identity[:id].to_s

    stream_from "turbo_presence:#{@room}"
    TurboPresence.store.join(@room, @user_id, @identity)
    broadcast_presence
  rescue TurboPresence::RoomToken::InvalidToken
    reject
  end

  def unsubscribed
    return unless @room

    TurboPresence.store.leave(@room, @user_id)
    broadcast_presence
  end

  def cursor(data)
    x = data["x"].to_f.clamp(0.0, 1.0)
    y = data["y"].to_f.clamp(0.0, 1.0)
    TurboPresence.store.update_cursor(@room, @user_id, x: x, y: y)
    ActionCable.server.broadcast("turbo_presence:#{@room}", {
      type:    "cursor",
      user_id: @user_id,
      x:       x,
      y:       y
    })
  end

  def typing(data)
    ActionCable.server.broadcast("turbo_presence:#{@room}", {
      type:    "typing",
      user_id: @user_id,
      name:    @identity[:name],
      active:  data["active"]
    })
  end

  def heartbeat
    TurboPresence.store.touch(@room, @user_id)
  end

  private

  def broadcast_presence
    ActionCable.server.broadcast("turbo_presence:#{@room}", {
      type:  "presence",
      users: TurboPresence.store.all(@room).values
    })
  end
end
