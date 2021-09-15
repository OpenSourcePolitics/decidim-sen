# frozen_string_literal: true

module Decidim
  module Initiatives
    # A command with all the business logic that updates an
    # existing initiative.
    class UpdateInitiative < Rectify::Command
      include ::Decidim::MultipleAttachmentsMethods
      include CurrentLocale

      # Public: Initializes the command.
      #
      # initiative - Decidim::Initiative
      # form       - A form object with the params.
      def initialize(initiative, form, current_user)
        @form = form
        @initiative = initiative
        @current_user = current_user
        @attached_to = initiative
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if form.invalid?

        if existing_documents? || drop_documents_ids.present?
          @initiative.attachments.where(id: drop_documents_ids).destroy_all if drop_documents_ids.present?
        end

        if process_attachments?
          build_attachments
          return broadcast(:invalid) if attachments_invalid?

          create_attachments
        end

        @initiative = Decidim.traceability.update!(
          initiative,
          current_user,
          attributes
        )

        broadcast(:ok, initiative)
      rescue ActiveRecord::RecordInvalid
        broadcast(:invalid, initiative)
      end

      private

      attr_reader :form, :initiative, :current_user

      def attributes
        attrs = {
          title: { current_locale => form.title },
          description: { current_locale => form.description },
          hashtag: form.hashtag
        }

        if form.signature_type_updatable?
          attrs[:signature_type] = initiative.signature_type
          attrs[:scoped_type_id] = form.scoped_type_id if form.scoped_type_id
        end

        if form.initiative_type != initiative.type
          attrs[:scoped_type_id] = initiative_type_scope(form.type_id).id if initiative_type_scope(form.type_id).present?
        end

        if initiative.created?
          attrs[:signature_end_date] = form.signature_end_date if initiative.custom_signature_end_date_enabled?
        end

        attrs
      end

      def initiative_type_scope(type_id)
        available_initiative_types.find(type_id)&.scopes&.first
      end

      # Return all initiative types with scopes defined.
      # Copied from Decidim::Initiatives::TypeSelectorOptions, tests doesn't have context to load method `available_initiative_types`
      def available_initiative_types
        Decidim::Initiatives::InitiativeTypes
          .for(@initiative.organization)
          .joins(:scopes)
          .distinct
      end
    end
  end
end
