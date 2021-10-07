# frozen_string_literal: true

module Decidim
  module Initiatives
    class Permissions < Decidim::DefaultPermissions
      def permissions
        # Delegate the admin permission checks to the admin permissions class
        return Decidim::Initiatives::Admin::Permissions.new(user, permission_action, context).permissions if permission_action.scope == :admin
        return permission_action if permission_action.scope != :public

        # Non-logged users permissions
        public_report_content_action?
        list_public_initiatives?
        read_public_initiative?
        search_initiative_types_and_scopes?
        request_membership?

        return permission_action unless user

        create_initiative?
        edit_public_initiative?
        update_public_initiative?
        create_initiative_with_type?

        vote_initiative?
        sign_initiative?
        unvote_initiative?

        initiative_attachment?

        initiative_committee_action?
        send_to_technical_validation?

        permission_action
      end

      private

      def initiative
        @initiative ||= context.fetch(:initiative, nil) || context.fetch(:current_participatory_space, nil)
      end

      def initiative_type
        @initiative_type ||= context[:initiative_type]
      end

      def list_public_initiatives?
        allow! if permission_action.subject == :initiative &&
                  permission_action.action == :list
      end

      def read_public_initiative?
        return unless [:initiative, :participatory_space].include?(permission_action.subject) &&
                      permission_action.action == :read

        return allow! if readable?(initiative)
        return allow! if user && authorship_or_admin?

        disallow!
      end

      def search_initiative_types_and_scopes?
        return unless permission_action.action == :search
        return unless [:initiative_type, :initiative_type_scope, :initiative_type_signature_types].include?(permission_action.subject)

        allow!
      end

      def create_initiative?
        return unless permission_action.subject == :initiative &&
                      permission_action.action == :create

        toggle_allow(creation_enabled?)
      end

      def edit_public_initiative?
        return unless permission_action.subject == :initiative &&
                      permission_action.action == :edit

        toggle_allow(initiative&.created? && authorship_or_admin?)
      end

      def update_public_initiative?
        return unless permission_action.subject == :initiative &&
                      permission_action.action == :update

        toggle_allow(initiative&.created? && authorship_or_admin?)
      end

      def creation_enabled?
        Decidim::Initiatives.creation_enabled && (
        creation_authorized? || Decidim::UserGroups::ManageableUserGroups.for(user).verified.any?
      )
      end

      def create_initiative_with_type?
        return unless permission_action.subject == :initiative_type &&
                      permission_action.action == :create

        toggle_allow(creation_enabled_for?(initiative_type))
      end

      def creation_enabled_for?(initiative_type)
        Decidim::Initiatives.creation_enabled && (
        creation_authorized_for?(initiative_type) || Decidim::UserGroups::ManageableUserGroups.for(user).verified.any?
      )
      end

      def request_membership?
        return unless permission_action.subject == :initiative &&
                      permission_action.action == :request_membership

        toggle_allow(can_request_membership?)
      end

      def can_request_membership?
        return access_request_without_user? if user.blank?

        access_request_membership?
      end

      def access_request_without_user?
        !initiative.published? && initiative.promoting_committee_enabled? || Decidim::Initiatives.do_not_require_authorization
      end

      def access_request_membership?
        !initiative.validating? &&
          !initiative.published? &&
          initiative.promoting_committee_enabled? &&
          !initiative.has_authorship?(user) &&
          !user_signataire? &&
          (
          Decidim::Initiatives.do_not_require_authorization ||
              ActionAuthorizer.new(user, :create, initiative, initiative_type).authorize.ok? ||
              Decidim::UserGroups::ManageableUserGroups.for(user).verified.any?
        )
      end

      def user_signataire?
        user.email.blank? && user.name == "Anonyme"
      end

      def vote_initiative?
        return unless permission_action.action == :vote &&
                      permission_action.subject == :initiative

        toggle_allow(can_vote?)
      end

      def authorized?(permission_action, resource: nil, permissions_holder: nil)
        return unless resource || permissions_holder

        ActionAuthorizer.new(user, permission_action, permissions_holder, resource).authorize.ok?
      end

      def creation_authorized?
        return true if Decidim::Initiatives.do_not_require_authorization
        return true if available_verification_workflows.empty?
        # decidim-sen customization
        # creation authorized if managed user
        return true if user.managed?

        Decidim::Initiatives::InitiativeTypes.for(user.organization).find do |type|
          ActionAuthorizer.new(user, :create, type, type).authorize.ok?
        end.present?
      end

      def creation_authorized_for?(initiative_type)
        return true if Decidim::Initiatives.do_not_require_authorization
        return true if available_verification_workflows.empty?
        # decidim-sen customization
        # creation authorized if managed user
        return true if user.managed?

        ActionAuthorizer.new(user, :create, initiative_type, initiative_type).authorize.ok?
      end

      def unvote_initiative?
        return unless permission_action.action == :unvote &&
                      permission_action.subject == :initiative

        can_unvote = initiative.accepts_online_unvotes? &&
                     initiative.organization&.id == user.organization&.id &&
                     initiative.votes.where(author: user).any? &&
                     authorized?(:vote, resource: initiative, permissions_holder: initiative.type)

        toggle_allow(can_unvote)
      end

      def initiative_attachment?
        return unless permission_action.action == :add_attachment &&
                      permission_action.subject == :initiative

        toggle_allow(initiative_type.attachments_enabled?)
      end

      def public_report_content_action?
        return unless permission_action.action == :create &&
                      permission_action.subject == :moderation

        allow!
      end

      def sign_initiative?
        return unless permission_action.action == :sign_initiative &&
                      permission_action.subject == :initiative

        can_sign = can_vote? &&
                   context.fetch(:signature_has_steps, false)

        toggle_allow(can_sign)
      end

      def decidim_user_group_id
        context.fetch(:group_id, nil)
      end

      def can_vote?
        initiative.votes_enabled? &&
          initiative.organization&.id == user.organization&.id &&
          initiative.votes.where(author: user).empty? &&
          authorized?(:vote, resource: initiative, permissions_holder: initiative.type)
      end

      def can_user_support?(initiative)
        !initiative.offline_signature_type? && (
        Decidim::Initiatives.do_not_require_authorization ||
            UserAuthorizations.for(user).any?
      )
      end

      def readable?(initiative)
        return false if initiative.blank?

        initiative.published? || initiative.rejected? || initiative.accepted? || initiative.debatted? || initiative.examinated? || initiative.classified?
      end

      def initiative_committee_action?
        return unless permission_action.subject == :initiative_committee_member

        request = context.fetch(:request, nil)
        return unless user.admin? || initiative&.has_authorship?(user)

        case permission_action.action
        when :index
          allow!
        when :approve
          toggle_allow(!request&.accepted?)
        when :revoke
          toggle_allow(!request&.rejected?)
        end
      end

      def send_to_technical_validation?
        return unless permission_action.action == :send_to_technical_validation &&
                      permission_action.subject == :initiative

        toggle_allow(initiative.created? && allowed_to_send_to_technical_validation? && author_or_admin?)
      end

      def allowed_to_send_to_technical_validation?
        !initiative.created_by_individual? || initiative.enough_committee_members?
      end

      def author_or_admin?
        initiative.author == user || user.admin?
      end

      def authorship_or_admin?
        initiative&.has_authorship?(user) || user.admin?
      end
    end
  end
end
