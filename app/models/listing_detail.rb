class ListingDetail < ActiveRecord::Base
  attr_accessible :body, :body_type, :source, :user_id
  has_one :listing
  before_create :make_listing
  serialize :body

  def make_listing
    if self.source == "craigslist"
      if self.body_type == "JSON"
        self.build_listing(:latitude => self.body["location"]["lat"],
                           :longitude => self.body["location"]["long"],
                           :price => self.body["price"],
                           :bedrooms => three_taps_annotations["bedrooms"],
                           :address => self.body["location"]["formatted_address"],
                           :body => "#{self.body["body"]}".gsub(/&\w{1,5};/, ''),
                           :u_id => self.body["id"],
                           :user_id => self.user_id)
      end
    elsif self.source == "zillow" and self.body_type.match(/xml/i)
      self.build_listing(self.zillow_attributes)
    end
  end

  def three_taps_annotations
    if self.body["annotations"].is_a?(Array)
      return self.body["annotations"][0]
    elsif self.body["annotations"].is_a?(Hash)
      return self.body["annotations"]
    else
      return nil
    end
  end

  def zillow_attributes
    #integer, latitude: float, longitude: float, bedrooms: integer, price: integer, address: string, created_at: datetime, updated_at: datetime, info: text, dogs: boolean, cats: boolean, body: text, u_id: string, listing_detail_id: integer, user_id: integer, expired_at: datetime)

    noko = Nokogiri::XML(self.body)
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
