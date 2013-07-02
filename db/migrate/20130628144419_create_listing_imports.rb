class CreateListingImports < ActiveRecord::Migration
  def change
    create_table :listing_imports do |t|
      t.datetime :completed_at
      t.integer :listing_importer_id
      t.integer :new_listings, default: 0
      t.integer :updated_listings, default: 0
      t.integer :failed_listings, default: 0
      t.string :current_anchor
      t.datetime :current_date

      t.timestamps
    end
  end
end
