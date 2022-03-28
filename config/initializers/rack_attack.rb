# frozen_string_literal: true

Rack::Attack.safelist_ip(ENV["POD_IP"]) if ENV["POD_IP"].present?
Rack::Attack.enabled = false if ENV.fetch("RACK_ATTACK_DISABLED", false)
