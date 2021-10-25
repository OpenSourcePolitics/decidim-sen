# frozen_string_literal: true
# This migration comes from decidim_initiatives (originally 20210421150245)

class CreateDecidimInitiativesArchiveCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :decidim_initiatives_archive_categories do |t|
      t.string :name
      t.references :decidim_organization,
                   foreign_key: true,
                   index: {
                     name:
                         "index_archive_categories_on_decidim_organization_id"
                   }
      t.timestamps
    end
  end
end
