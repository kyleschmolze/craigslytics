class RemoveAnalysisIdFromListings < ActiveRecord::Migration
  def change
    remove_column :listings, :analysis_id
  end
end
