class Tag < ActiveRecord::Base
  attr_accessible  :name, :display, :search_term, :complexity, :category, :parent
  has_many :listing_tags 
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

end
