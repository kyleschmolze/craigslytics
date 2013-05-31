class CreateAnalysisListingJoinTable < ActiveRecord::Migration
  def change
    create_table :analyses_listings, :id => false do |t|
      t.integer :analysis_id
      t.integer :listing_id
    end
  end
end
