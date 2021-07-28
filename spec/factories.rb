# frozen_string_literal: true

require "decidim/core/test/factories"
require "decidim/system/test/factories"
require "decidim/initiatives/test/factories"
require "decidim/comments/test/factories"

FactoryBot.modify do
  factory :initiative, class: "Decidim::Initiative" do
    title { generate_localized_title }
    description { generate_localized_title }
    organization
    author { create(:user, :confirmed, organization: organization) }
    published_at { Time.current }
    state { "published" }
    signature_type { "online" }
    signature_start_date { Date.current - 1.day }
    signature_end_date { Date.current + 120.days }
    online_votes { { "total": 0 } }
    offline_votes { { "total": 0 } }
    answer_date {}
    area {}
    decidim_initiatives_archive_categories_id {}

    scoped_type do
      create(:initiatives_type_scope,
             type: create(:initiatives_type, organization: organization, signature_type: signature_type))
    end

    after(:create) do |initiative|
      if initiative.author.is_a?(Decidim::User) && Decidim::Authorization.where(user: initiative.author).where.not(granted_at: nil).none?
        create(:authorization, user: initiative.author, granted_at: Time.now.utc)
      end
      create_list(:initiatives_committee_member, 3, initiative: initiative)
    end

    trait :with_area do
      area { create(:area, organization: organization) }
    end

    trait :archived do
      decidim_initiatives_archive_categories_id { create(:archive_category, organization: organization).id }
    end

    trait :with_answer do
      answer { Decidim::Faker::Localized.wrapped("<p>", "</p>") { generate_localized_title } }
      answer_url { ::Faker::Internet.url }
      answered_at { Time.current }
    end

    trait :created do
      state { "created" }
      published_at { nil }
      signature_start_date { nil }
      signature_end_date { nil }
    end

    trait :validating do
      state { "validating" }
      published_at { nil }
      signature_start_date { nil }
      signature_end_date { nil }
    end

    trait :published do
      state { "published" }
    end

    trait :unpublished do
      published_at { nil }
    end

    trait :accepted do
      state { "accepted" }
    end

    trait :discarded do
      state { "discarded" }
    end

    trait :rejected do
      state { "rejected" }
    end

    trait :examinated do
      state { "examinated" }
      answer_date { Date.current - 3.days }
    end

    trait :debatted do
      state { "debatted" }
      answer_date { Date.current - 3.days }
    end

    trait :classified do
      state { "classified" }
      answer_date { Date.current - 3.days }
    end

    trait :online do
      signature_type { "online" }
    end

    trait :offline do
      signature_type { "offline" }
    end

    trait :acceptable do
      signature_start_date { Date.current - 3.months }
      signature_end_date { Date.current - 2.months }
      signature_type { "online" }

      after(:build) do |initiative|
        initiative.online_votes["total"] = initiative.supports_required + 1
      end
    end

    trait :rejectable do
      signature_start_date { Date.current - 3.months }
      signature_end_date { Date.current - 2.months }
      signature_type { "online" }

      after(:build) do |initiative|
        initiative.online_votes["total"] = 0
      end
    end

    trait :with_user_extra_fields_collection do
      scoped_type do
        create(:initiatives_type_scope,
               type: create(:initiatives_type, :with_user_extra_fields_collection, organization: organization))
      end
    end

    trait :with_area do
      area { create(:area, organization: organization) }
    end
  end
end
