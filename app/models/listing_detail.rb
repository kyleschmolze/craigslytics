class ListingDetail < ActiveRecord::Base
  attr_accessible :body, :body_type, :source, :raw_body, :user_id
  attr_accessor :raw_body

  has_one :listing, autosave: true

  after_initialize :set_raw_body
  before_validation :store
  before_create :make_listing
  
  validate do |listing|
    if listing.source == "craigslist"
      if listing.body_type == "JSON"
        if Listing.where(:u_id => listing.raw_body["id"]).present? 
           listing.errors[:base] << "Not unique -- Already in database"
        end
      end
    end
  end 

  def store
    self.body = Marshal.dump(self.raw_body)
  end

  def set_raw_body
    self.raw_body ||= Marshal.load(self.body)
  end

  def make_listing
    if self.source == "craigslist" and self.body_type == "JSON"
      self.build_listing(self.craigslist_attributes)
    elsif self.source == "zillow" and self.body_type.match(/xml/i)
      self.build_listing(self.zillow_attributes)
    end
  end

  def three_taps_annotations
    raw = self.raw_body
    if raw["annotations"].is_a?(Array)
      return raw["annotations"][0]
    elsif raw["annotations"].is_a?(Hash)
      return raw["annotations"]
    else
      return nil
    end
  end

  def craigslist_attributes
    raw = self.raw_body
    {
      :latitude => raw["location"]["lat"],
      :longitude => raw["location"]["long"],
      :price => raw["price"],
      :bedrooms => three_taps_annotations["bedrooms"],
      :address => raw["location"]["formatted_address"],
      :timestamp => raw["timestamp"],
      :u_id => raw["id"]
    }
  end

  def zillow_attributes
    noko = Nokogiri::XML(self.raw_body)
    {
      :latitude => noko.css("latitude").text,
      :longitude => noko.css("longitude").text,
      :price => noko.css("rent").text,
      :bedrooms => noko.css("bedrooms").text,
      :address => noko.css("address").text,
      :u_id => noko.css("rentjuice_id").text,
      :user_id => self.user_id
    }
  end

end
