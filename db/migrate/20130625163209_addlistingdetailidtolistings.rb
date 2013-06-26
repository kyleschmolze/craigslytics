class Addlistingdetailidtolistings < ActiveRecord::Migration
  def change
    add_column :listings, :listing_detail_id, :integer
  end
end
