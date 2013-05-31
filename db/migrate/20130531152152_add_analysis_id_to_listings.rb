class AddAnalysisIdToListings < ActiveRecord::Migration
  def change
    add_column :listings, :analysis_id, :integer
    add_column :listings, :info, :text
  end
end
