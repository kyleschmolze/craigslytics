class CreateUtilityAnalyses < ActiveRecord::Migration
  def change
    create_table :utility_analyses do |t|
      t.boolean :fresh
      t.integer :tag_id
      t.integer :listing_id
      t.text :listings_with
      t.text :listings_without

      t.timestamps
    end
  end
end
