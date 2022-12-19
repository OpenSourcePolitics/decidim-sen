# frozen_string_literal: true

module Decidim
  class AnonymizeInitiativesService
    def self.run
      new.execute
    end

    def execute
      Decidim::Organization.find_each do |organization|
        Decidim::Initiative.where("created_at < ?", offset_duration).each do |initiative|
          @deleted_user ||= Decidim::User.where(organization: organization).where.not(deleted_at: nil).first || Decidim::User.create!(
            name: "Deleted user",
            organization: organization,
            deleted_at: Time.current,
            password: SecureRandom.hex(10),
            tos_agreement: "1"
          )
          Rails.logger.info "Anonymizing initiative #{initiative.id}"
          initiative.update!(author: @deleted_user)
        end
      end
    end

    def offset_duration
      time, unity = ENV.fetch("ANONYMIZE_INITIATIVES", "3.years").split(".")

      raise "Invalid time format" unless time.to_i.positive? && unity.in?(%w(days day month months year years))

      time.to_i.send(unity).ago.at_midnight
    end
  end
end
