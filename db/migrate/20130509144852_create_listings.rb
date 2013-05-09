class CreateListings < ActiveRecord::Migration
  def change
    create_table :listings do |t|
      t.float :latitude
      t.float :longitude
      t.integer :bedrooms
      t.integer :price
      t.string :address

      t.timestamps
    end
  end
end
