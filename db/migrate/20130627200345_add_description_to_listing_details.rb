class AddDescriptionToListingDetails < ActiveRecord::Migration
  def change
    add_column :listing_details, :description, :text
  end
end
