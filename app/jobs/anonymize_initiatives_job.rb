# frozen_string_literal: true

class AnonymizeInitiativesJob < ApplicationJob
  queue_as :scheduled

  def perform
    Decidim::AnonymizeInitiativesService.run
  end
end
