class Tag < ActiveRecord::Base
  attr_accessible  :name, :display, :search_term, :complexity, :category
  has_many :listing_tags 
  has_many :listings, through: :listing_tags

  validate do |t| 
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

  TYPES = {
    house: "single family", 
    condo: "condo",
    apartment_building: "complex", # or "building"
    apartment: "" 
  }

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
    ListingTag.create({listing_id: l.id, tag_id: self.id}) if ( l.listing_detail.raw_body["body"].match /\b#{self.search_term}\b/ )
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

    if self.category == "unit_type" then detect_unit_type l

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



  # TODO make a class method, call from Listing.generate_tags
  # validation in listing_tag only allows 1 unit_type
  def detect_unit_type(l)
    
    if self.name == "house" or self.name == "condo" # search for these first
      m = l.listing_detail.raw_body["body"].match /\b#{self.search_term}/i   # searches for "condominuim" as well
      ListingTag.create({listing_id: l.id, tag_id: self.id}) if m
    elsif self.name == "building"
      m1 = l.listing_detail.raw_body["body"].match /\bcomplex\b/i
      m2 = l.listing_detail.raw_body["body"].match /\bbuilding\b/i
      ListingTag.create({listing_id: l.id, tag_id: self.id}) if m1 or m2

    # assuming there are no complete bullshit listings that aren't anything,
    # everything else should be listed as just an 'apartment'
    elsif self.name == "apartment"
      ListingTag.create({listing_id: l.id, tag_id: self.id}) 
    end
  end

  def extract_field(l)
    puts 'extracting.........'
    noko = Nokogiri::XML(l.listing_detail.raw_body)
    if self.category == "amenity"
      features = noko.css("features")
      features.each do |f|
        puts "==============================\n"
        puts f.text
        puts "\n" + self.search_term
        puts "==============================\n"
        if f.text.match /#{self.search_term}/i
          puts 'success!'
          ListingTag.create({listing_id: l.id, tag_id: self.id}) 
        end
      end
    elsif self.category == "utility"
      terms = noko.css("rental_terms")
      terms.each do |t|
        ListingTag.create({listing_id: l.id, tag_id: self.id}) if t.text.match /#{self.search_term}/i
      end
    elsif self.category == "unit_type"
      variable = "variable"
      # property_type
      # building_name
      # description
      # received_description
    end
  end
end
