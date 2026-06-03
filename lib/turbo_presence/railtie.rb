# frozen_string_literal: true

module TurboPresence
  class Railtie < Rails::Railtie
    initializer "turbo_presence.helpers" do
      ActiveSupport.on_load(:action_view) do
        include TurboPresence::ViewHelper
      end
    end

    initializer "turbo_presence.store" do
      TurboPresence.initialize_store!
    end

    initializer "turbo_presence.assets" do |app|
      if app.config.respond_to?(:assets)
        app.config.assets.paths << root.join("app/javascript").to_s
      end
    end
  end
end
