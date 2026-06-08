# frozen_string_literal: true

require "spec_helper"
require "uri"
require "cgi"
require "bigdecimal"
require "action_view"
require "turbo_presence/view_helper"
require "turbo_presence/room_token"

# Minimal Rails stub needed for RoomToken.sign
module Rails
  def self.application
    @application ||= Struct.new(:secret_key_base).new("a" * 64)
  end
end unless defined?(Rails)

RSpec.describe TurboPresence::ViewHelper do
  # Stand up a minimal host object that has what the view helper needs
  let(:host_class) do
    Class.new do
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::OutputSafetyHelper
      include TurboPresence::ViewHelper

      attr_reader :current_user

      def initialize(user)
        @current_user = user
        @output_buffer = ActionView::OutputBuffer.new
      end
    end
  end

  let(:agent) { double("Agent", id: 1, name: "Alice Chen", color: "#4f46e5") }
  let(:helper) { host_class.new(agent) }

  let(:record) do
    double("Ticket", class: double(name: "Ticket"), id: 42)
  end

  before do
    TurboPresence.configure do |c|
      c.identify_user { |u| { id: u.id, name: u.name, color: u.color } }
    end
  end

  describe "#turbo_presence_for" do
    subject(:html) { helper.turbo_presence_for(record) }

    it "renders a div with the turbo-presence Stimulus controller" do
      expect(html).to include('data-controller="turbo-presence"')
    end

    it "sets room-token as a Stimulus value (with -value suffix)" do
      expect(html).to match(/data-turbo-presence-room-token-value="[A-Za-z0-9_-]+"/)
    end

    it "sets identity as a Stimulus value (with -value suffix)" do
      expect(html).to include("data-turbo-presence-identity-value=")
    end

    it "encodes the identity as JSON containing id, name, and color" do
      identity_json = html.match(/data-turbo-presence-identity-value="([^"]+)"/)[1]
      identity = JSON.parse(CGI.unescapeHTML(identity_json))
      expect(identity).to include("id" => 1, "name" => "Alice Chen", "color" => "#4f46e5")
    end

    it "sets cursors-value to true by default" do
      expect(html).to include('data-turbo-presence-cursors-value="true"')
    end

    it "sets typing-value to true by default" do
      expect(html).to include('data-turbo-presence-typing-value="true"')
    end

    it "sets throttle-value from configuration" do
      expect(html).to include("data-turbo-presence-throttle-value=")
    end

    it "includes the turbo-presence CSS class" do
      expect(html).to include("turbo-presence")
    end

    it "accepts an extra CSS class" do
      output = helper.turbo_presence_for(record, class: "relative block")
      expect(output).to include("turbo-presence relative block")
    end

    it "renders block content inside the div" do
      output = helper.turbo_presence_for(record) { "inner content" }
      expect(output).to include("inner content")
    end

    it "does NOT use the old attribute names without -value suffix" do
      # These were the buggy attribute names from v0.1.0
      expect(html).not_to match(/data-turbo-presence-room-token="[^v]/)
      expect(html).not_to match(/data-turbo-presence-identity="[^v]/)
    end
  end
end
