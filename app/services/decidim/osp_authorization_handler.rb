# frozen_string_literal: true

module Decidim
  # Authorization handler for user impersonation
  class OspAuthorizationHandler < AuthorizationHandler
    attribute :document_number, String

    validates :document_number, presence: true

    def metadata
      super.merge(document_number: document_number)
    end

    def unique_id
      document_number
    end
  end
end
