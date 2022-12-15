# frozen_string_literal: true

namespace :decidim_initiatives do
  desc "Check created initiatives and send them to technical validation after a configured time"
  task check_created: :environment do
    Decidim::Initiatives::OutdatedCreatedInitiatives
      .for(72.hours)
      .each do |initiative|
      Decidim::Initiatives::Admin::SendInitiativeToTechnicalValidation.call(initiative, initiative.author)
    end
  end

  desc "Check for 3 years old initiatives and anonymize them"
  task check_old: :environment do
    Decidim::CheckAnonymizableInitiativesService.run
  end
end
