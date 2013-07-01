class AddMetroToListingImporters < ActiveRecord::Migration
  def change
    add_column :listing_importers, :metro, :string
  end
end
