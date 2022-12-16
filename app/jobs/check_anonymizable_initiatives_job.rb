# frozen_string_literal: true

class CheckAnonymizableInitiativesJob < ApplicationJob
  unique :while_executing, on_conflict: :log
  queue_as :anonymize_initiatives

  def perform
    Decidim::CheckAnonymizableInitiativesService.run
  end
end
