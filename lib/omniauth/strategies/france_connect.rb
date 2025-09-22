# frozen_string_literal: true

require "omniauth_openid_connect"

module OmniAuth
  module Strategies
    class FranceConnect < OmniAuth::Strategies::OpenIDConnect
      option :name, :france_connect
      option :origin_param, "redirect_url"

      option :site
      option :client_id
      option :client_secret
      # option :end_session_endpoint

      option :scope, %w(openid email preferred_username)
      option :client_signing_alg, :ES256
      option :discovery, true
      option :response_type, "code"
      option :client_auth_method, "basic"
      option :uid_field, "sub"

      option :scope, [:openid, :email, :preferred_username]
      option :client_signing_alg, :HS256
      option :client_auth_method, :body
      option :acr_values, "eidas1"

      info do
        {
          name: "#{user_info.given_name} #{find_name}".strip,
          email: user_info.email,
          nickname: ::Decidim::UserBaseEntity.nicknamize(find_name),
          first_name: user_info.given_name&.strip,
          last_name: find_name&.strip
        }
      end

      def find_name
        user_info.preferred_username.presence || user_info.family_name
      end

      def authorize_uri
        super + (options.acr_values.present? ? "&acr_values=#{options.acr_values}" : "")
      end

      def auth_hash
        hash = super
        hash.logout = end_session_uri
        hash
      end

      def end_session_uri
        return unless end_session_endpoint_is_valid?

        end_session_uri = URI(client_options.end_session_endpoint)
        end_session_uri.query = URI.encode_www_form(
          id_token_hint: credentials[:id_token],
          state: new_state,
          post_logout_redirect_uri: options.post_logout_redirect_uri
        )
        end_session_uri.to_s
      end

      def user_info
        return @user_info if @user_info

        if access_token.id_token
          decoded = decode_id_token(access_token.id_token).raw_attributes

          response = access_token.userinfo!
          response = decode_id_token(response) if response.is_a?(String)

          log :debug, "Userinfo response: #{response.raw_attributes.to_h}"

          @user_info = ::OpenIDConnect::ResponseObject::UserInfo.new response.raw_attributes.merge(decoded).deep_symbolize_keys
        else
          @user_info = access_token.userinfo!
        end
      end

      private

      def client_options
        site_url = URI(options.issuer)

        options.client_options.merge(
          host: site_url.host,
          port: site_url.port,
          identifier: options.client_id,
          secret: options.client_secret,
          authorization_endpoint: "/api/v2/authorize",
          token_endpoint: "/api/v2/token",
          userinfo_endpoint: "/api/v2/userinfo",
          jwks_uri: "/api/v2/jwks",
          end_session_endpoint: "#{options.issuer}/session/end"
        )
      end

      def redirect_uri
        return omniauth_callback_url unless params["redirect_uri"]

        "#{omniauth_callback_url}?redirect_uri=#{CGI.escape(params["redirect_uri"])}"
      end

      def omniauth_callback_url
        full_host + script_name + callback_path
      end

      def new_state
        session["omniauth.state"] = SecureRandom.hex(16)
      end

      def session_state
        session["omniauth.state"] = params["state"] || SecureRandom.hex(16)
      end

      def other_phase
        call_app!
      end
    end
  end
end
