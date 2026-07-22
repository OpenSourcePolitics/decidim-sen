# frozen_string_literal: true

require "omniauth/strategies/france_connect_uid"
require "omniauth/strategies/france_connect_profile"

OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  OmniAuth.config.logger = Rails.logger
  omniauth_config = Rails.application.secrets.dig(:omniauth)

  if omniauth_config[:france_connect_uid].present?
    provider(
      :france_connect_uid,
      setup: setup_provider_proc(:france_connect_uid,
                                 issuer: :site,
                                 client_id: :client_id,
                                 client_secret: :client_secret,
                                 post_logout_redirect_uri: :post_logout_redirect_uri,
                                 icon_path: :icon_path,
                                 button_path: :button_path,
                                 provider_name: :provider_name,
                                 minimum_age: :minimum_age)
    )
  end

  if omniauth_config[:france_connect_profile].present?
    provider(
      :france_connect_profile,
      setup: setup_provider_proc(:france_connect_profile,
                                 issuer: :site,
                                 client_id: :client_id,
                                 client_secret: :client_secret,
                                 post_logout_redirect_uri: :post_logout_redirect_uri,
                                 icon_path: :icon_path,
                                 button_path: :button_path,
                                 provider_name: :provider_name,
                                 minimum_age: :minimum_age)
    )
  end
end
