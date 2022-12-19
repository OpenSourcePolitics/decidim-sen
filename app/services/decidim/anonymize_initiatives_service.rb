# frozen_string_literal: true

module Decidim
  class AnonymizeInitiativesService
    def self.run
      new.execute
    end

    def execute
      query
    end

    # return a hash with the following structure:
    # {
    #   organization_id => {
    #     author_id => [initiative_id]
    #   }
    # }
    def query
      Decidim::Initiative.where("created_at < ?", offset_duration)
                         .preload(:organization, :author)
                         .each_with_object({}) do |initiative, hash|
        hash[initiative.organization] ||= {}
        hash[initiative.organization][initiative.author] ||= []
        hash[initiative.organization][initiative.author] << initiative
      end
    end

    def offset_duration
      time, unity = ENV.fetch("ANONYMIZE_INITIATIVES", "3.years").split(".")

      raise "Invalid time format" unless time.to_i.positive? && unity.in?(%w(days day month months year years))

      time.to_i.send(unity).ago.at_midnight
    end
  end
end
