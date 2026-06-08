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
      gem_root = Pathname.new(__dir__).join("../..")
      app.config.assets.paths << gem_root.join("app/javascript").to_s if app.config.respond_to?(:assets)
    end
  end
end
