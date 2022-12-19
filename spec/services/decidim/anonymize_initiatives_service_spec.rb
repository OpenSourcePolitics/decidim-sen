# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe AnonymizeInitiativesService do
    let(:organization) { create(:organization) }
    let!(:initiative) { create(:initiative, organization: organization) }
    let!(:initiative2) { create(:initiative, organization: organization, created_at: 4.years.ago) }
    let!(:initiative3) { create(:initiative, organization: organization) }

    describe "#execute" do
      it "anonymizes initiatives older than 3 years" do
        expect(initiative2.author).not_to be_deleted
        described_class.run
        expect(initiative2.reload.author).to be_deleted
        expect(initiative.reload.author).not_to be_deleted
        expect(initiative3.reload.author).not_to be_deleted
      end
    end

    describe "#offset_duration" do
      it "returns the default time" do
        expect(described_class.new.offset_duration).to eq(3.years.ago.at_midnight)
      end

      context "when ANONYMIZE_INITIATIVES is set" do
        before do
          ENV["ANONYMIZE_INITIATIVES"] = "1.day"
        end

        after do
          ENV["ANONYMIZE_INITIATIVES"] = nil
        end

        it "returns the configured time" do
          expect(described_class.new.offset_duration).to eq(1.day.ago.at_midnight)
        end

        context "when the time is invalid" do
          before do
            ENV["ANONYMIZE_INITIATIVES"] = "x.foobar"
          end

          after do
            ENV["ANONYMIZE_INITIATIVES"] = nil
          end

          it "raises an error" do
            expect { described_class.new.offset_duration }.to raise_error("Invalid time format")
          end
        end
      end
    end
  end
end
