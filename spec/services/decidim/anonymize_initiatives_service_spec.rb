# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe AnonymizeInitiativesService do
    let!(:organization1) { create(:organization) }
    let!(:organization2) { create(:organization) }

    let!(:user1) { create(:user, :confirmed, organization: organization1) }
    let!(:user2) { create(:user, :confirmed, organization: organization1) }
    let!(:user3) { create(:user, :confirmed, organization: organization2) }
    let!(:user4) { create(:user, :confirmed, organization: organization1) }

    let!(:user_group) { create(:user_group, :verified, users: [user1], organization: organization1) }

    let!(:authorization) { create(:authorization, user: user1) }
    let!(:authorization2) { create(:authorization, user: user2) }
    let!(:authorization3) { create(:authorization, user: user3) }
    let!(:authorization4) { create(:authorization, user: user4) }

    let!(:initiative1) { create(:initiative, organization: organization1, author: user1, created_at: 4.years.ago) }
    let!(:initiative2) { create(:initiative, organization: organization1, author: user1, created_at: 4.years.ago) }

    let!(:initiative3) { create(:initiative, organization: organization1, author: user2, created_at: 4.years.ago) }
    let!(:initiative4) { create(:initiative, organization: organization2, author: user3, created_at: 4.years.ago) }

    let!(:initiative5) { create(:initiative, organization: organization1, author: user4, created_at: 1.years.ago) }

    let!(:initiative6) { create(:initiative, organization: organization1, author: user_group, created_at: 4.years.ago) }

    describe "#execute" do
      it "anonymize initiatives older than 3 years" do
        described_class.run

        expect(initiative1.reload.author).to be_deleted
        expect(initiative2.reload.author).to be_deleted
        expect(initiative1.reload.author).to eq(initiative2.reload.author)

        expect(initiative3.reload.author).to be_deleted
        expect(initiative4.reload.author).to be_deleted

        expect(initiative5.reload.author).not_to be_deleted

        expect(initiative6.reload.author).not_to be_deleted

      end
    end

    describe "#query" do
      it "returns initiatives older than 3 years" do
        query = described_class.new.query

        expect(query).to be_a(Hash)
        expect(query.keys).to match_array([organization1, organization2])

        expect(query[organization1]).to be_a(Hash)
        expect(query[organization1].keys).to match_array([user1, user2, user_group])
        expect(query[organization1][user1]).to match_array([initiative1, initiative2])
        expect(query[organization1][user2]).to match_array([initiative3])
        expect(query[organization1][user_group]).to match_array([initiative6])

        expect(query[organization2]).to be_a(Hash)
        expect(query[organization2].keys).to match_array([user3])
        expect(query[organization2][user3]).to match_array([initiative4])
      end
    end

    describe "#anonymize" do
      it "anonymize initiatives" do
        anonymize = described_class.new.anonymize(organization1, user1, [initiative1, initiative2])

        expect(anonymize).to eq([initiative1, initiative2])
        expect(anonymize.first.author).to be_deleted
        expect(anonymize.last.author).to be_deleted

        expect(anonymize.first.author).to eq(anonymize.last.author)
      end

      context "when author is a user group" do
        it "anonymize initiatives" do
          anonymize = described_class.new.anonymize(organization1, user_group, [initiative6])

          expect(anonymize).to eq(nil)
        end
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
