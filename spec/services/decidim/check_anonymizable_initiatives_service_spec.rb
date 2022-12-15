# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe CheckAnonymizableInitiativesService do
    let(:organization) { create(:organization) }
    let!(:initiative) { create(:initiative, organization: organization) }
    let!(:initiative2) { create(:initiative, organization: organization, created_at: 4.years.ago) }
    let!(:initiative3) { create(:initiative, organization: organization) }

    it "anonymizes initiatives older than 3 years" do
      expect(initiative2.author).not_to be_deleted
      described_class.run
      expect(initiative2.reload.author).to be_deleted
      expect(initiative.reload.author).not_to be_deleted
      expect(initiative3.reload.author).not_to be_deleted
    end
  end
end
