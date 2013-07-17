class UtilityAnalysis < ActiveRecord::Base
  attr_accessible :fresh, :listing_id, :listings_with, :listings_without, :tag_id, :price_difference
  belongs_to :tag
  belongs_to :listing

  def get_listings_with
    ids = self.listings_with.split(",").map{|id| id.to_i}
    return Listing.where(id: ids)
  end

  def get_listings_without
    ids = self.listings_without.split(",").map{|id| id.to_i}
    return Listing.where(id: ids)
  end
end
