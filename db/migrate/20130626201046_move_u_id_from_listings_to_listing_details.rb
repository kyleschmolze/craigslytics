class MoveUIdFromListingsToListingDetails < ActiveRecord::Migration
  def up
    remove_column :listings, :u_id
    add_column :listing_details, :u_id, :string
  end

  def down
    add_column :listings, :u_id, :string
    remove_column :listing_details, :u_id
  end
end
