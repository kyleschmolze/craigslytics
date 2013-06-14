class Tag < ActiveRecord::Base
  attr_accessible :listing_id, :name
  belongs_to :listing

  NAMES = [
    "Garden",
    "Patio",
    "Window",
    "Stove",
    "Hardwood",
    "View"
  ]

  #name[matcher]

  UTILITIES = {
    water: "water"
  }

end
