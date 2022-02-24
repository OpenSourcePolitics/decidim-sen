# frozen_string_literal: true

Rack::Attack.enabled = false if ENV.fetch("RACK_ATTACK_DISABLED", false)
