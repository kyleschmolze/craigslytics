class AddUidIndexToListings < ActiveRecord::Migration
  def change
    add_index :listings, :u_id
  end
end
