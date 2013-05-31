class Listing < ActiveRecord::Base
  attr_accessible :address, :bedrooms, :latitude, :longitude, :price, :analysis_id, :info
  serialize :info

  has_and_belongs_to_many :analyses

end
