class Listing < ActiveRecord::Base
  attr_accessible :address, :bedrooms, :latitude, :longitude, :price, :analysis_id, :info
  serialize :info

  has_and_belongs_to_many :analyses

  def create_comparison_with(a_listing)
    
    # WEIGHTS
    address_weight    = 1 
    bedrooms_weight   = 1 
    latitude_weight  = 1
    longitude_weight = 1
    price_weight      = 1

    diff_squared = (address_weight * (self.address == a_listing.address ? 1 : 0))    + 
                   (bedrooms_weight * (self.bedrooms - a_listing.bedrooms)**2)       + 
                   (latitude_weight * (self.latitude - a_listing.latitude)**2)    +
                   (longitude_weight * (self.longitude - a_listing.longitude)**2) +
                   (price_weight * (self.price - a_listing.price)**2) 
    
    ListingComparison.new({:listing_1_id=>self.id, :listing_2_id=>a_listing.id, :score=>diff_squared})

  end
end
