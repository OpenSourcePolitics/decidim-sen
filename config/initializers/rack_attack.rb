if ENV.fetch("RACK_ATTACK_DISABLED", false)
  Rack::Attack.enabled = false
end