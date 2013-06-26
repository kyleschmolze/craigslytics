class AddTimestampToListings < ActiveRecord::Migration
  def change
    add_column :listings, :timestamp, :integer
  end
end
