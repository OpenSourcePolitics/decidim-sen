# frozen_string_literal: true

module Decidim
  class AnonymizeInitiativesService
    def self.run
      new.execute
    end

    def execute
      Decidim::Initiative.transaction do
        query.map do |organization, data|
          data.map do |author, initiatives|
            anonymize(organization, author, initiatives)
          end
        end.flatten
             .compact
             .each(&:save!)
      end
    end

    # return a hash with the following structure:
    # {
    #   organization => {
    #     author => [initiative, initiative, initiative]
    #   }
    # }
    def query
      Decidim::Initiative.where("decidim_initiatives.created_at < ?", offset_duration)
                         .joins(:organization)
                         .preload(:author)
                         .each_with_object({}) do |initiative, hash|
        hash[initiative.organization] ||= {}
        hash[initiative.organization][initiative.author] ||= []
        hash[initiative.organization][initiative.author] << initiative
      end
    end

    def anonymize(organization, author, initiatives)
      return if author.is_a?(Decidim::UserGroup)
      return if author.deleted?

      deleted_user = Decidim::User.create!(
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
