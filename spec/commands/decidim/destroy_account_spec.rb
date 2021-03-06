# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe DestroyAccount do
    let(:command) { described_class.new(user, form) }
    let(:user) { create(:user, :confirmed) }
    let!(:identity) { create(:identity, user: user) }
    let(:valid) { true }
    let(:data) do
      {
        delete_reason: "I want to delete my account"
      }
    end

    let(:form) do
      form = double(
        delete_reason: data[:delete_reason],
        valid?: valid
      )

      form
    end

    context "when invalid" do
      let(:valid) { false }

      it "broadcasts invalid" do
        expect { command.call }.to broadcast(:invalid)
      end
    end

    context "when valid" do
      let(:valid) { true }

      it "broadcasts ok" do
        expect { command.call }.to broadcast(:ok)
      end

      it "stores the deleted_at and delete_reason to the user" do
        command.call
        expect(user.reload.delete_reason).to eq(data[:delete_reason])
        expect(user.reload.deleted_at).not_to be_nil
      end

      it "set name, nickname and email to blank string" do
        command.call
        expect(user.reload.name).to eq("")
        expect(user.reload.nickname).to eq("")
        expect(user.reload.email).to eq("")
      end

      it "destroys the current user avatar" do
        command.call
        expect(user.reload.avatar).not_to be_present
      end

      it "deletes user's identities" do
        expect do
          command.call
        end.to change(Identity, :count).by(-1)
      end

      it "deletes user group memberships" do
        user_group = create(:user_group)
        create(:user_group_membership, user_group: user_group, user: user)

        expect do
          command.call
        end.to change(UserGroupMembership, :count).by(-1)
      end

      it "deletes the follows" do
        other_user = create(:user)
        create(:follow, followable: user, user: other_user)
        create(:follow, followable: other_user, user: user)

        expect do
          command.call
        end.to change(Follow, :count).by(-2)
      end

      context "when user has initiative" do
        let!(:initiative) { create(:initiative, scoped_type: scoped_type, organization: scoped_type.type.organization) }
        let!(:scoped_type) { create(:initiatives_type_scope, supports_required: 1) }
        let(:command) { described_class.new(initiative.author, form) }

        context "when initiative has reached the signature threshold" do
          before do
            create(:initiative_user_vote, initiative: initiative)
          end

          it "Sets the initiative state as accepted" do
            command.call
            expect(initiative.reload.state).to eq("accepted")
          end
        end

        context "when initiative has not reached the signature threshold" do
          context "when initiative has created state" do
            let!(:initiative) { create(:initiative, :created, scoped_type: scoped_type, organization: scoped_type.type.organization) }

            it "is discarded" do
              command.call
              expect(initiative.reload.state).to eq("discarded")
            end
          end

          context "when initiative has technical validation" do
            let!(:initiative) { create(:initiative, :validating, scoped_type: scoped_type, organization: scoped_type.type.organization) }

            it "is discarded" do
              command.call
              expect(initiative.reload.state).to eq("discarded")
            end
          end

          it "Sets the initiative state as rejected" do
            command.call
            expect(initiative.reload.state).to eq("rejected")
          end
        end
      end
    end
  end
end
