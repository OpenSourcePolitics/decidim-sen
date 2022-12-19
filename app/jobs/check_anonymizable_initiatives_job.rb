# frozen_string_literal: true

class CheckAnonymizableInitiativesJob < ApplicationJob
  queue_as :scheduled
  unique :while_executing, on_conflict: :log

  def perform
    Decidim::CheckAnonymizableInitiativesService.run
  end
end
