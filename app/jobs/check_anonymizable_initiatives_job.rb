# frozen_string_literal: true

class CheckAnonymizableInitiativesJob < ApplicationJob
  def perform
    Decidim::CheckAnonymizableInitiativesService.run
  end
end
