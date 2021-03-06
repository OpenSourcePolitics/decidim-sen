# frozen_string_literal: true

# require 'extends/confirmations_controller_extend'
require "extends/user_model_extend"
require "extends/account_form_extend"
require "extends/omniauth_registration_form_extend"
require "extends/initiative_admin_form_extend" if defined?(Decidim::Initiatives)
require "extends/organization_appearance_form_extend"
require "extends/update_organization_appearance_extend"
require "extends/destroy_account_extend"
require "extends/create_omniauth_registration_extend"
require "extends/update_account_extend"
