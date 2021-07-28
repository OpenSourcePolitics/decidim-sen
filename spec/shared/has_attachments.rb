# frozen_string_literal: true

require "spec_helper"

shared_examples_for "has attachments" do
  context "when it has attachments", processing_uploads_for: Decidim::AttachmentUploader do
    let!(:document) { create(:attachment, :with_pdf, attached_to: attached_to) }

    before do
      visit current_path
    end

    it "shows them" do
      within "div.wrapper .documents" do
        expect(page).to have_content(/#{translated(document.title, locale: :en)}/i)
      end
    end
  end

  context "when are ordered by weight", processing_uploads_for: Decidim::AttachmentUploader do
    let!(:last_document) { create(:attachment, :with_pdf, attached_to: attached_to, weight: 2) }
    let!(:first_document) { create(:attachment, :with_pdf, attached_to: attached_to, weight: 1) }

    before do
      visit current_path
    end

    it "shows them ordered" do
      within "div.wrapper .documents" do
        expect(translated(first_document.title, locale: :en)).to appear_before(translated(last_document.title, locale: :en))
      end
    end
  end
end
