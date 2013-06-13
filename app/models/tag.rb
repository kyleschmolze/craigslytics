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

  UTILITIES = [
    elec: "Electricity",
    water: "Water",
    heat: "Heat"
  ]

end
