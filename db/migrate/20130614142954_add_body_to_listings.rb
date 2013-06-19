class AddBodyToListings < ActiveRecord::Migration
  def change
    add_column :listings, :body, :text
  end
end
