# frozen_string_literal: true

class AnonymizeInitiativesJob < ApplicationJob
  queue_as :scheduled
  unique :while_executing, on_conflict: :log

  def perform
    Decidim::AnonymizeInitiativesService.run
  end
end
