class ChangeColumnsOnListings < ActiveRecord::Migration
  def up
    remove_column :listings, :info
    remove_column :listings, :body
    remove_column :listings, :dogs
    remove_column :listings, :cats
    remove_column :listing_details, :listing_id
    add_column :listings, :bathrooms, :string
  end

  def down
    add_column :listings, :info, :text
    add_column :listings, :body, :text
    add_column :listings, :dogs, :boolean
    add_column :listings, :cats, :boolean
    add_column :listing_details, :listing_id, :integer
    remove_column :listings, :bathrooms
  end
end
