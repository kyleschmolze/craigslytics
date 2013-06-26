class AddUserIdToListingsAndListingDetails < ActiveRecord::Migration
  def change
    add_column :listings, :user_id, :integer
    add_column :listing_details, :user_id, :integer
  end
end
