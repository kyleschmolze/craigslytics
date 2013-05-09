class Listing < ActiveRecord::Base
  attr_accessible :address, :bedrooms, :latitude, :longitude, :price
end
