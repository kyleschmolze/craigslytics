class CreateListingDetails < ActiveRecord::Migration
  def change
    create_table :listing_details do |t|
      t.integer :listing_id
      t.string :source
      t.text :body
      t.string :body_type

      t.timestamps
    end
  end
end
