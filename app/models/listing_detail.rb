class ListingDetail < ActiveRecord::Base
  attr_accessible :body, :body_type, :source
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
                           :u_id => self.body["id"])
      end
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

end
