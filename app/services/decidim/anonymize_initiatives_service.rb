# frozen_string_literal: true

module Decidim
  class AnonymizeInitiativesService
    def self.run
      new.execute
    end

    def execute
      Rails.logger.info "########## Anonymizing initiatives ##########"
      Rails.logger.info "Ready to anonymize initiatives created before #{offset_duration}"
      Rails.logger.info "Processing #{anonymized_initiatives.count} initiatives with #{anonymized_initiatives.map(&:author).uniq.count} authors"
      Rails.logger.info "Anonymizing initiatives..."

      Decidim::Initiative.transaction do
        anonymized_initiatives.each(&:save!)
      end

      Rails.logger.info "Anonymization finished"
      Rails.logger.info "####################"
    end

    def anonymized_initiatives
      @anonymized_initiatives ||= query.map do |organization, initiatives|
        anonymize(organization, initiatives)
      end.flatten.compact
    end

    # return a hash with the following structure:
    # {
    #   organization => [initiative, initiative, initiative]
    # }
    def query
      Decidim::Initiative.where("decidim_initiatives.created_at < ?", offset_duration)
                         .joins(:organization)
                         .preload(:author)
                         .each_with_object({}) do |initiative, hash|
        hash[initiative.organization] ||= []
        hash[initiative.organization] << initiative unless initiative.author.is_a?(Decidim::UserGroup) || initiative.author.deleted?
      end
    end

    def anonymize(organization, initiatives)
      deleted_user = Decidim::User.where(organization: organization).where.not(deleted_at: nil).first || Decidim::User.create!(
        name: "Deleted user",
        organization: organization,
        deleted_at: Time.current,
        password: SecureRandom.hex(10),
        tos_agreement: "1"
      )

      initiatives.map do |initiative|
        initiative.tap { |i| i.author = deleted_user }
      end
    end

    def offset_duration
      time, unity = ENV.fetch("ANONYMIZE_INITIATIVES", "3.years").split(".")

      raise "Invalid time format" unless time.to_i.positive? && unity.in?(%w(days day month months year years))

      time.to_i.send(unity).ago.at_midnight
    end
  end
end
