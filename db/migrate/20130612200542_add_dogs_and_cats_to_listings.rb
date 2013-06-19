class AddDogsAndCatsToListings < ActiveRecord::Migration
  def change
    add_column :listings, :dogs, :boolean
    add_column :listings, :cats, :boolean
  end
end
