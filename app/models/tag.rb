class Tag < ActiveRecord::Base
  attr_accessible  :name, :display, :search_term, :complexity, :category, :parent
  has_many :listing_tags 
  has_many :utility_analyses
  has_many :listings, through: :listing_tags

  validate do |t| 
    t.errors[:base] << "cannot create duplicate tags" if Tag.where(:name => t.name).exists?
  end

  # For Unit Types, complexity is specificity (level in tree structure)
  #
  #                            1           apartment
  #                                       /         \
  #                            2       house       townhouse    etc.

  def raw_search_term
    Marshal.load(self.search_term)
  end

  def self.average_with_util(tags, utility, listings)
    include_tag_list = tags + [utility]
    include_tag_list = include_tag_list.uniq
    exclude_tag_list = Tag.where(category: "utility").all - include_tag_list

    ids = []
    for tag in include_tag_list do
      ids << tag.listings.map{|l| l.id}
    end
    if ids.present?
      ids = ids.inject(:&)
    end
    ids = [ids]

    for tag in exclude_tag_list do
      ids << tag.listings.map{|l| l.id}
    end
    return ids = ids.inject(:-)
    #puts "ids: #{ids}"
    
    prices = listings.where(id: ids).map{|l| l.price} 
    #puts "prices: #{prices}"
    len = prices.count
    if len > 0
      med = (prices[(len - 1) / 2] + prices[len / 2]) / 2 
    else
      med = nil
    end
    #puts "average: #{med}"
    return med
  end

  def self.average_without_util(tags, utility, listings)
    include_tag_list = tags - [utility]
    exclude_tag_list = Tag.where(category: "utility").all - include_tag_list

    ids = []
    for tag in include_tag_list do
      ids << tag.listings.map{|l| l.id}
    end
    if ids.present?
      ids = ids.inject(:&)
    end
    ids = [ids]

    for tag in exclude_tag_list do
      ids << tag.listings.map{|l| l.id}
    end
    return ids = ids.inject(:-)
    #puts "ids: #{ids}"

    prices = listings.where(id: ids).map{|l| l.price} 
    #puts "prices: #{prices}"
    len = prices.count
    if len > 0
      med = (prices[(len - 1) / 2] + prices[len / 2]) / 2 
    else
      med = nil
    end
    #puts "average: #{med}"
    return med
  end

  def detect_in_listing(l)
    if l.listing_detail.raw_body.present?
      if l.listing_detail.raw_body["body"].present?
        if self.complexity == 1   
          detect_simple l       
        elsif self.complexity == 2
          detect_medium l 
        else 
          detect_complex l
        end
      end
    end
  end

  def detect_simple(l)
    ListingTag.create({listing_id: l.id, tag_id: self.id}) if ( l.listing_detail.raw_body["body"].match /#{self.raw_search_term}/i )
  end


  def detect_medium(l)
    range = 40
    m1 = (l.listing_detail.raw_body["body"].match /\binclud.{0,#{range}}\b#{self.raw_search_term}\b/i)
    m2 = (l.listing_detail.raw_body["body"].match /\b#{self.raw_search_term}\b.{0,#{range}}\binclud/i)
    if m1 or m2 
      ListingTag.create({listing_id: l.id, tag_id: self.id}) 
    end
  end

  def detect_complex(l)
    range = 40 
    if self.name == "gas" 
      m1 = (l.listing_detail.raw_body["body"].match /\binclud.{0,#{range}}\b#{self.raw_search_term}\b/i)
      m2 = (l.listing_detail.raw_body["body"].match /\b#{self.raw_search_term}\b.{0,#{range}}\binclud/i)
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
      q1 = (l.listing_detail.raw_body["body"].match /.{25}\b#{self.raw_search_term}/i)
      if q1
        ListingTag.create({listing_id: l.id, tag_id: self.id}) unless q1[0].match /partially/i
      end
    end
  end


  # For Unit Types, complexity is specificity (level in tree structure)
  def assign_unit_type(l)
    if l.listing_detail.raw_body.present?
      if l.listing_detail.source == ("craigslist") and l.listing_detail.raw_body["body"].present?
        craigslist_unit_type l
      elsif l.listing_detail.source == ("zillow")
        noko = Nokogiri::XML(l.listing_detail.raw_body)
        zillow_unit_type l, noko
      elsif l.listing_detail.source == ("ygl")
        noko = Nokogiri::XML(l.listing_detail.raw_body)
        ygl_unit_type l, noko
      end
    end
  end

  def craigslist_unit_type l 
    if ( l.listing_detail.raw_body["body"].match /#{self.raw_search_term}/i )
      ListingTag.create({listing_id: l.id, tag_id: self.id}) 
      ListingTag.create({listing_id: l.id, tag_id: Tag.where(name: self.parent).first.id}) if self.parent
    end
  end

  def ygl_unit_type(l, noko) 
    if noko.at_css("BuildingType")
      building_type = noko.at_css("BuildingType").text
      if self.name == "apartment" 
        ListingTag.create({listing_id: l.id, tag_id: self.id}) 
      elsif building_type.match /#{self.raw_search_term}/i
        ListingTag.create({listing_id: l.id, tag_id: self.id})
        ListingTag.create({listing_id: l.id, tag_id: Tag.where(name: self.parent).first.id}) if self.parent
      end
    end
  end

  def zillow_unit_type(l, noko) 
    prop_type = noko.at_css("property_type") 
    if prop_type.text.match /#{self.raw_search_term}/i
      ListingTag.create({listing_id: l.id, tag_id: self.id}) 
      ListingTag.create({listing_id: l.id, tag_id: Tag.where(name: self.parent).first.id}) if self.parent
    else
      received_desc = noko.at_css("received_description")
      if received_desc.text.match /#{self.raw_search_term}/i
        ListingTag.create({listing_id: l.id, tag_id: self.id}) 
        ListingTag.create({listing_id: l.id, tag_id: Tag.where(name: self.parent).first.id}) if self.parent
      end
    end
  end

  def ygl_extract_field(l)
    if l.listing_detail.raw_body.present?
      noko = Nokogiri::XML(l.listing_detail.raw_body)

      if self.category == "amenity"
        features = noko.css("Features")
        features.each do |f|  # suspect there is only one item, checking whole thing
          if f.text.match /#{self.raw_search_term}/i
            ListingTag.create({listing_id: l.id, tag_id: self.id}) 
          end
        end
      elsif self.category == "utility"
        if self.name == "gas"
          if t = noko.css("IncludeGas")
            ListingTag.create({listing_id: l.id, tag_id: self.id}) if t.text.match /1/i
          end
        end
        if self.name == "water"
          if t = noko.css("IncludeHotWater")
            ListingTag.create({listing_id: l.id, tag_id: self.id}) if t.text.match /1/i
          end
        end
        if self.name == "heat"
          if t = noko.css("IncludeHeat")
            ListingTag.create({listing_id: l.id, tag_id: self.id}) if t.text.match /1/i
          end
        end
        if self.name == "electric"
          if t = noko.css("IncludeElectricity")
            ListingTag.create({listing_id: l.id, tag_id: self.id}) if t.text.match /1/i
          end
        end
        if self.name == "cats" or self.name == "dogs"
          if t = noko.css("Pet")
            ListingTag.create({listing_id: l.id, tag_id: self.id}) if !t.text.match /No Pet/i
          end
        end
      end
    end
  end

  def zillow_extract_field(l)
    if l.listing_detail.raw_body.present?
      noko = Nokogiri::XML(l.listing_detail.raw_body)

      # parse for fields we know are there; i.e. parking
      zillow_extract_specific_fields l

      if self.category == "amenity"
        features = noko.css("features")
        features.each do |f|
          if f.text.match /#{self.raw_search_term}/i
            ListingTag.create({listing_id: l.id, tag_id: self.id}) 
          end
        end
      elsif self.category == "utility"
        terms = noko.css("rental_terms")
        terms.each do |t|
          ListingTag.create({listing_id: l.id, tag_id: self.id}) if t.text.match /#{self.raw_search_term}/i
        end
      end
    end
  end

  def zillow_extract_specific_fields(l)
    noko = Nokogiri::XML(l.listing_detail.raw_body)
    # parking
    if self.name == "parking"
      if !(noko.at_css("parking_spaces").text.blank? and noko.at_css("parking_space_type").text.blank?)
        ListingTag.create({listing_id: l.id, tag_id: self.id}) 
      end
    end
  end

  def self.create_init_tags

    # bundled utilities
    self.create({name:'water', display:'water', search_term: Marshal.dump('water'), complexity:'2', category:'utility'})
    self.create({name:'electric', display:'electricity', search_term: Marshal.dump('electric'), complexity:'2', category:'utility'})
    self.create({name:'gas', display:'gas', search_term: Marshal.dump('gas'), complexity:'3', category:'utility'})
    self.create({name:'heat', display:'heat', search_term: Marshal.dump('heat'), complexity:'2', category:'utility'})
    self.create({name:'internet', display:'internet', search_term: Marshal.dump('internet'), complexity:'3', category:'utility'})
    self.create({name:'cable', display:'cable', search_term: Marshal.dump('cable'), complexity:'3', category:'utility'})


    # unit_types
    self.create({name:'apartment', display:'apartment', search_term: Marshal.dump(''), complexity:'1', category:'unit_type'})
    self.create({name:'building', display:'apt. complex', search_term: Marshal.dump('complex'), complexity:'2', category:'unit_type', parent:'apartment'})
    self.create({name:'house', display:'house', search_term: Marshal.dump('family home'), complexity:'2', category:'unit_type', parent:'apartment'})
    self.create({name:'townhouse', display:'townhouse', search_term: Marshal.dump('town ?house'), complexity:'2', category:'unit_type', parent:'apartment'})
    self.create({name:'condo', display:'(condo)', search_term: Marshal.dump('condo'), complexity:'3', category:'unit_type', parent:'townhouse'})
    self.create({name:'luxury', display:'(luxury)', search_term: Marshal.dump('luxury'), complexity:'3', category:'unit_type', parent:'building'})
    self.create({name:'high rise', display:'(high rise)', search_term: Marshal.dump('high ?rise'), complexity:'3', category:'unit_type', parent:'building'})
    self.create({name:'brownstone', display:'(brownstone)', search_term: Marshal.dump('brown ?stone'), complexity:'3', category:'unit_type', parent:'townhouse'})
    self.create({name:'colonial', display:'(colonial)', search_term: Marshal.dump('colonial'), complexity:'3', category:'unit_type', parent:'house'})
    self.create({name:'victorian', display:'(victorian)', search_term: Marshal.dump('victorian'), complexity:'3', category:'unit_type', parent:'house'})

    # amenities
    self.create({name:'cats', display:'cats allowed', search_term: Marshal.dump('cat'), complexity:'1', category:'amenity'})
    self.create({name:'dogs', display:'dogs allowed', search_term: Marshal.dump('dog'), complexity:'1', category:'amenity'})
    self.create({name:'parking', display:'parking', search_term: Marshal.dump('parking'), complexity:'1', category:'amenity'})
    self.create({name:'fireplace', display:'fireplace', search_term: Marshal.dump('fire ?place'), complexity:'1', category:'amenity'})
    self.create({name:'garden', display:'garden', search_term: Marshal.dump('garden'), complexity:'1', category:'amenity'})
    self.create({name:'stove', display:'stove', search_term: Marshal.dump('stove'), complexity:'1', category:'amenity'})
    self.create({name:'view', display:'view', search_term: Marshal.dump('view'), complexity:'1', category:'amenity'})
    self.create({name:'high ceilings', display:'high ceilings', search_term: Marshal.dump('high ceiling'), complexity:'1', category:'amenity'})
    self.create({name:'carpeted', display:'carpeted', search_term: Marshal.dump('carpet'), complexity:'1', category:'amenity'})
    self.create({name:'tile floors', display:'tile floors', search_term: Marshal.dump('tile floor'), complexity:'1', category:'amenity'})
    self.create({name:'granite counters', display:'granite countertops', search_term: Marshal.dump('granite counter'), complexity:'1', category:'amenity'})
    self.create({name:'marble counters', display:'marble countertops', search_term: Marshal.dump('marble counter'), complexity:'1', category:'amenity'})
    self.create({name:'recently remodeled', display:'recently remodeled', search_term: Marshal.dump('recently remodeled'), complexity:'1', category:'amenity'})
    self.create({name:'dishwasher', display:'dishwasher', search_term: Marshal.dump('dish ?washer'), complexity:'1', category:'amenity'})
    self.create({name:'microwave', display:'microwave', search_term: Marshal.dump('microwave'), complexity:'1', category:'amenity'})
    self.create({name:'balcony', display:'balcony', search_term: Marshal.dump('balcony'), complexity:'1', category:'amenity'})
    self.create({name:'garbage disposal', display:'garbage disposal', search_term: Marshal.dump('garbage disposal'), complexity:'1', category:'amenity'})
    self.create({name:'patio', display:'patio', search_term: Marshal.dump('patio'), complexity:'1', category:'amenity'})
    self.create({name:'hardwood', display:'hardwood floors', search_term: Marshal.dump('hard ?wood'), complexity:'1', category:'amenity'})
    self.create({name:'laundry', display:'laundry', search_term: Marshal.dump('laundry'), complexity:'1', category:'amenity'})
    self.create({name:'roof deck', display:'roof deck', search_term: Marshal.dump('roof ?deck'), complexity:'1', category:'amenity'})
    self.create({name:'renovated', display:'renovated', search_term: Marshal.dump('renovated'), complexity:'1', category:'amenity'})
    self.create({name:'air conditioning', display:'air conditioning', search_term: Marshal.dump('air condition'), complexity:'1', category:'amenity'})
    self.create({name:'doorman', display:'doorman', search_term: Marshal.dump('door ?man'), complexity:'1', category:'amenity'})
    self.create({name:'concierge', display:'concierge', search_term: Marshal.dump('concierge'), complexity:'1', category:'amenity'})
    self.create({name:'gym', display:'gym', search_term: Marshal.dump('gym'), complexity:'1', category:'amenity'})
    self.create({name:'walk-in closet', display:'walk-in closet', search_term: Marshal.dump('walk-? ?in ?-?closet'), complexity:'1', category:'amenity'})

  end

end
