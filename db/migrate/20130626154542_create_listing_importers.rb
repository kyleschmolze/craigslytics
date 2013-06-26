class CreateListingImporters < ActiveRecord::Migration
  def change
    create_table :listing_importers do |t|
      t.integer :user_id
      t.string :api_key
      t.string :source

      t.timestamps
    end
  end
end
