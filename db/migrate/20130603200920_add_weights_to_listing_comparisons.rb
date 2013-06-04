class AddWeightsToListingComparisons < ActiveRecord::Migration
  def change
    add_column :listing_comparisons, :address_score, :float
    add_column :listing_comparisons, :bedrooms_score, :float
    add_column :listing_comparisons, :location_score, :float
    add_column :listing_comparisons, :price_score, :float
  end
end
