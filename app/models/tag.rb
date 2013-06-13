class Tag < ActiveRecord::Base
  attr_accessible :listing_id, :name

  NAMES = [
    "Garden",
    "Patio"
  ]

  UTILITIES = [
    elec: "Electricity",
    water: "Water"
  ]

  #within listing.parse
  #for name in Tag::NAMES
    #if listing.whatever.match name
      #Tag.create
  #scan 
end
