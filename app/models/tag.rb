class Tag < ActiveRecord::Base
  attr_accessible  :name, :display, :search_term, :complexity, :category
  has_many :listing_tags 
  has_many :listings, through: :listing_tags

  validate do |t| 
    t.errors[:complexity] << "tag complexity must be 1, 2, or 3" if !self.complexity.between?(1,3)
  end

  NAMES = [
    "Garden",
    "Patio",
    "Fireplace",
    "Stove",
    "Hardwood",
    "View",
    "High Ceilings",
    "Carpeted",
    "Tile Floors",
    "Granite Counter",
    "Marble Counter",
    "Recently Remodeled",
    "Dishwasher",
    "Microwave",
    "Balcony",
    "Garbage Disposal",
    "Tub"
  ]

  UTILITIES = {
    water: "water",  # confirmed simple
    electricity: "electric",  # confirmed simple
    heat: "heat",              # confirmed simple
    cable: "cable",   # confirmed simple
    internet: "internet",  # confirmed simple
    gas: "gas" # complex
  }

  TYPES = {
    house: "single family",
    condo: "condo",
    apartment_building: "complex", # or "building"
    apartment: "" 
  }

  def detect_in_listing(l)
    if l.body.present?
      if self.complexity == 1        # Validation says complexity must be 1, 2, or 3
        detect_simple l              # so no funny business 
      elsif self.complexity == 2
        detect_medium l 
      else 
        detect_complex l
      end
    end
  end

  def detect_simple(l)
    ListingTag.create({listing_id: l.id, tag_id: self.id}) if ( l.body.match /\b#{self.search_term}\b/ )
  end

  def detect_medium(l)
    range = 40
    m1 = (l.body.match /\binclud.{0,#{range}}\b#{self.search_term}\b/i)
    m2 = (l.body.match /\b#{self.search_term}\b.{0,#{range}}\binclud/i)
    if m1 or m2 
      ListingTag.create({listing_id: l.id, tag_id: self.id}) 
    end
  end

  def detect_complex(l)
    range = 40 

    if self.name == "gas" 
      m1 = (l.body.match /\binclud.{0,#{range}}\b#{self.search_term}\b/i)
      m2 = (l.body.match /\b#{self.search_term}\b.{0,#{range}}\binclud/i)
      if m1 and m2
        # a little DeMorgan -- if any are true, don't do it
        if !(m1.match /\bgas.{0,3}range/ or m1.match /\bgas.{0,3}stove/ or m1.match /\bgas.{0,3}fireplace/ or m1.match /pay.{0,30}gas/)
          ListingTag.create({listing_id: l.id, tag_id: self.id}) 
        end
      end
    end

    if self.name == "internet"      # 'internet', 'wifi', 'wi-fi' 
      p1 = (l.body.match /\binclud.{0,#{range}}\binternet\b/i)
      p2 = (l.body.match /\binternet\b.{0,#{range}}\binclud/i)
      p3 = (l.body.match /\binclud.{0,#{range}}\bwifi\b/i)
      p4 = (l.body.match /\bwifi\b.{0,#{range}}\binclud/i)
      p5 = (l.body.match /\binclud.{0,#{range}}\bwi-fi\b/i)
      p6 = (l.body.match /\bwi-fi\b.{0,#{range}}\binclud/i)
      ListingTag.create({listing_id: l.id, tag_id: self.id}) if p1 or p2 or p3 or p4 or p5 or p6
    end

    if self.name == "furnished"
      q1 = (l.body.match /.{25}\b#{self.search_term}/i)
      if q1
        ListingTag.create({listing_id: l.id, tag_id: self.id}) unless q1.match /partially/i
      end
    end
  end

end
