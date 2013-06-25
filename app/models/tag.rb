class Tag < ActiveRecord::Base
  attr_accessible :listing_id, :name
  belongs_to :listing

  NAMES = [
    "Garden",
    "Patio",
    "Fireplace",
    "Stove",
    "Hardwood",
    "View"
    "High Ceilings"
    "Carpeted"
    "Tile Floors"
    "Granite Counter"
    "Marble Counter"
    "Remodeled"
    "Dishwasher"
    "Microwave"
    "Balcony"
    "Garbage Disposal"
    "Tub"
  ]

  # name[matcher]
  # all 'simple' utilities need only look for 'includ' within 30 chars
  UTILITIES = {
    water: "water",  # confirmed simple
    electricity: "electric",  # confirmed simple
    heat: "heat",              # confirmed simple
    cable: "cable",   # confirmed simple
    internet: "internet",  # confirmed simple
    gas: "gas",  # complex

=begin
  TYPES
    house: "single family"
    condo: "condo"
    apartment_building: "complex", or "building"
    apartment: 
=end
 
  }

end
