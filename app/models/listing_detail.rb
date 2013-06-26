class ListingDetail < ActiveRecord::Base
  attr_accessible :body, :body_type, :source, :raw_body
  attr_accessor :raw_body

  has_one :listing

  before_validation :store
  before_create :make_listing
  
  validate do |listing|
    b = listing.load_body
    if listing.source == "craigslist"
      if listing.body_type == "JSON"
        if Listing.where(:u_id => b["id"]).present? 
           listing.errors[:base] << "Not unique -- Already in database"
        end
      end
    end
  end 

  def store
    self.body = Marshal.dump(self.raw_body)
  end

  def load_body
    Marshal.load(self.body)
  end

  def make_listing
    b = self.load_body
    if self.source == "craigslist"
      if self.body_type == "JSON"
        self.build_listing(:latitude => b["location"]["lat"],
                           :longitude => b["location"]["long"],
                           :price => b["price"],
                           :bedrooms => three_taps_annotations["bedrooms"],
                           :address => b["location"]["formatted_address"],
                           :body => "#{b["body"]}".gsub(/&\w{1,5};/, ''),
                           :timestamp => b["timestamp"],
                           :u_id => b["id"])
      end
    end
  end

  def three_taps_annotations
    b = self.load_body
    if b["annotations"].is_a?(Array)
      return b["annotations"][0]
    elsif b["annotations"].is_a?(Hash)
      return b["annotations"]
    else
      return nil
    end
  end

end
