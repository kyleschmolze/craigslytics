class Tag < ActiveRecord::Base
  attr_accessible  :name, :display, :search_term, :complexity, :category
  has_many :listing_tags 
  has_many :listings, through: :listing_tags

  validate do |t| 
    t.errors[:base] << "cannot create duplicate tags" if Tag.where(:name => t.name).exists?
    t.errors[:complexity] << "must be 1, 2, or 3" if !self.complexity.between?(1,3)
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

  UNIT_TYPES = [   # could be used for recursive looping, order of priority
    "house",  
    "condo",
    "building",
    "townhouse", # brownstone
    "apartment" 
  ]

  def detect_in_listing(l)
    if l.listing_detail.raw_body["body"].present?
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
    ListingTag.create({listing_id: l.id, tag_id: self.id}) if ( l.listing_detail.raw_body["body"].match /\b#{self.search_term}\b/i )
  end

  def detect_medium(l)
    range = 40
    m1 = (l.listing_detail.raw_body["body"].match /\binclud.{0,#{range}}\b#{self.search_term}\b/i)
    m2 = (l.listing_detail.raw_body["body"].match /\b#{self.search_term}\b.{0,#{range}}\binclud/i)
    if m1 or m2 
      ListingTag.create({listing_id: l.id, tag_id: self.id}) 
    end
  end

  def detect_complex(l)
    range = 40 

    if self.category == "unit_type" 
      detect_unit_type l

    elsif self.name == "gas" 
      m1 = (l.listing_detail.raw_body["body"].match /\binclud.{0,#{range}}\b#{self.search_term}\b/i)
      m2 = (l.listing_detail.raw_body["body"].match /\b#{self.search_term}\b.{0,#{range}}\binclud/i)
      if m1 and m2
        # a little DeMorgan -- if any are true, don't do it
        if !(m1[0].match /\bgas.{0,3}range/ or m1[0].match /\bgas.{0,3}stove/ or m1[0].match /\bgas.{0,3}fireplace/ or m1[0].match /pay.{0,30}gas/)
          ListingTag.create({listing_id: l.id, tag_id: self.id}) 
        end
      end

    elsif self.name == "internet"      # 'internet', 'wifi', 'wi-fi' 
      p1 = (l.listing_detail.raw_body["body"].match /\binclud.{0,#{range}}\binternet\b/i)
      p2 = (l.listing_detail.raw_body["body"].match /\binternet\b.{0,#{range}}\binclud/i)
      p3 = (l.listing_detail.raw_body["body"].match /\binclud.{0,#{range}}\bwi-?fi\b/i)
      p4 = (l.listing_detail.raw_body["body"].match /\bwi-?fi\b.{0,#{range}}\binclud/i)
      ListingTag.create({listing_id: l.id, tag_id: self.id}) if p1 or p2 or p3 or p4

    elsif self.name == "furnished"
      q1 = (l.listing_detail.raw_body["body"].match /.{25}\b#{self.search_term}/i)
      if q1
        ListingTag.create({listing_id: l.id, tag_id: self.id}) unless q1[0].match /partially/i
      end
    end
  end

  # validation in listing_tag only allows 1 unit_type
  # could also be done recursively, the future is wide open
  def self.detect_unit_type(l)
    found = false
    found = detect_unit('house', l)
    found = detect_unit('condo', l) if !found
    found = detect_unit('building', l) if !found
    found = detect_unit('townhouse', l) if !found
    if !found and tag = self.where(:name => 'apartment').first
      ListingTag.create({listing_id: l.id, tag_id: tag.id})
      # assumes there are no bs listings, al undefined are just apartments 
    end
  end

  def self.detect_unit(u, l)
    utag = Tag.where(:name => u).first
    return false if utag.blank?

    if u == "building"
      if l.listing_detail.raw_body["body"].match /#{utag.search_term}/i or l.listing_detail.raw_body["body"].match /complex/i
        ListingTag.create({listing_id: l.id, tag_id: utag.id})
        return true
      end
    elsif u == "townhouse"
      if l.listing_detail.raw_body["body"].match /#{utag.search_term}/i or l.listing_detail.raw_body["body"].match /brownstone/i
        ListingTag.create({listing_id: l.id, tag_id: utag.id})
        return true
      end
    elsif l.listing_detail.raw_body["body"].match /#{utag.search_term}/i
      ListingTag.create({listing_id: l.id, tag_id: utag.id})
      return true
    else
      return false
    end
  end

  def extract_field(l)
    noko = Nokogiri::XML(l.listing_detail.raw_body)

    # parse for fields we know are there; i.e. parking
    extract_specific_fields l

    if self.category == "amenity"
      features = noko.css("features")
      features.each do |f|
        if f.text.match /#{self.search_term}/i
          ListingTag.create({listing_id: l.id, tag_id: self.id}) 
        end
      end
    elsif self.category == "utility"
      terms = noko.css("rental_terms")
      terms.each do |t|
        ListingTag.create({listing_id: l.id, tag_id: self.id}) if t.text.match /#{self.search_term}/i
      end
    elsif self.category == "unit_type"
      prop_type = noko.at_css("property_type") 
      if prop_type.text.match /#{self.search_term}/i
        ListingTag.create({listing_id: l.id, tag_id: self.id}) 
      else
        desc = noko.at_css("description")
        received_desc = noko.at_css("received_description")
        if desc.text.match /#{self.search_term}/i or received_desc.text.match /#{self.search_term}/i
          ListingTag.create({listing_id: l.id, tag_id: self.id}) 
        end
      end
    end
  end

  def extract_specific_fields(l)
    # parking
    if self.name == "parking"
      if !(noko.at_css("parking").text.blank? and noko.at_css("parking_space_type").text.blank?)
        ListingTag.create({listing_id: l.id, tag_id: self.id}) 
      end
    end
  end

end
