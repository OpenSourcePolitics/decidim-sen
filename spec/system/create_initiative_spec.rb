# frozen_string_literal: true

require "spec_helper"

describe "Initiative", type: :system do
  let(:organization) { create(:organization) }
  let(:authorized_user) { create(:user, :confirmed, organization: organization) }

  shared_examples "initiatives path redirection" do
    it "redirects to initiatives path" do
      accept_confirm do
        click_link("Send my initiative")
      end

      expect(page).to have_current_path("/initiatives")
    end
  end
  before do
    create(:authorization, user: authorized_user)
    login_as authorized_user, scope: :user
  end
  context "when access to functionality" do
    before do
      switch_to_host(organization.host)

      create(:authorization, user: authorized_user)
      login_as authorized_user, scope: :user

      visit decidim_initiatives.initiatives_path
    end

    it "Initiatives page contains a create initiative button" do
      expect(page).to have_content("New initiative")
    end
  end

  context "when creates an initiative" do
    let(:initiative_type_minimum_committee_members) { 2 }
    let(:signature_type) { "any" }
    let(:initiative_type_promoting_committee_enabled) { true }
    let(:initiative_type) do
      create(:initiatives_type,
             organization: organization,
             minimum_committee_members: initiative_type_minimum_committee_members,
             promoting_committee_enabled: initiative_type_promoting_committee_enabled,
             signature_type: signature_type)
    end
    let!(:other_initiative_type) { create(:initiatives_type, organization: organization) }
    let!(:initiative_type_scope) { create(:initiatives_type_scope, type: initiative_type) }
    let!(:other_initiative_type_scope) { create(:initiatives_type_scope, type: initiative_type) }

    before do
      visit decidim_initiatives.create_initiative_path(id: :select_initiative_type)
    end

    context "when user is not defined and creates new initiative" do
      before do
        switch_to_host(organization.host)

        visit decidim_initiatives.initiatives_path
        click_link "New initiative"
      end

      it "redirects to select initiative type" do
        expect(page).to have_content("I want to promote this initiative")
      end

      context "when user click on promote initiative button" do
        it "opens the omniauth modal" do
          expect(page).to have_content("I want to promote this initiative")
          click_button "I want to promote this initiative"
          within "#loginModal" do
            expect(page).to have_content("PLEASE SIGN IN")
          end
        end
      end
    end
  end
end
