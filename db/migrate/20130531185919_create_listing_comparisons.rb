class CreateListingComparisons < ActiveRecord::Migration
  def change
    create_table :listing_comparisons do |t|
      t.integer :listing_1_id
      t.integer :listing_2_id
      t.float :score

      t.timestamps
    end
  end
end
