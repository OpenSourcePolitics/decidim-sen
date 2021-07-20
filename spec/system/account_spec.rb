# frozen_string_literal: true

require "spec_helper"

describe "Account", type: :system do
  let(:user) { create(:user, :confirmed, password: password, password_confirmation: password) }
  let(:password) { "dqCFgjfDbC7dPbrv" }
  let(:organization) { user.organization }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
  end

  describe "navigation" do
    it "shows the account form when clicking on the menu" do
      visit decidim.root_path

      within_user_menu do
        find("a", text: "PROFILE").click
      end

      expect(page).to have_css("form.edit_user")
    end
  end

  context "when on the account page" do
    before do
      visit decidim.account_path
    end

    it "doesn't display authorizations" do
      expect(page).to have_no_content("Authorizations")
    end

    describe "updating personal data" do
      it "updates the user's data" do
        within "form.edit_user" do
          expect(page).to have_field('user_name', readonly: true)

          fill_in :user_email, with: "nikola.tesla@example.org"

          perform_enqueued_jobs { find("*[type=submit]").click }
        end

        within_flash_messages do
          expect(page).to have_content("successfully")
        end

        within ".title-bar" do
          expect(page).to have_content(user.name)
        end

        user.reload

        within_user_menu do
          find("a", text: "PROFILE").click
        end

        expect(find("#user_email").value).to eq(user.email)
        expect(last_email.subject).to include("Instructions de confirmation")
      end
      context "when on the delete account modal" do
        it "the user can delete his account" do
          find("input.open-modal-button[type=\"submit\"]").click
          fill_in :delete_account_delete_reason, with: "I just want to delete my account"
          click_button "Yes, I want to delete my account"
          within_flash_messages do
            expect(page).to have_content("successfully")
          end
        end
      end
    end

    context "when on the notifications settings page" do
      before do
        visit decidim.notifications_settings_path
      end

      it "updates the user's notifications" do
        within ".switch.newsletter_notifications" do
          page.find(".switch-paddle").click
        end

        within "form.edit_user" do
          find("*[type=submit]").click
        end

        within_flash_messages do
          expect(page).to have_content("successfully")
        end
      end
    end
  end
end
