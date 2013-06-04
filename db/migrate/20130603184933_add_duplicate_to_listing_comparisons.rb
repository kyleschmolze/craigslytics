class AddDuplicateToListingComparisons < ActiveRecord::Migration
  def change
    add_column :listing_comparisons, :duplicate, :int, {:default=>0}
  end
end
