class ListingDetail < ActiveRecord::Base
  attr_accessible :body, :body_type, :source, :raw_body, :user_id, :u_id, :description
  attr_accessor :raw_body

  after_initialize :set_raw_body
  before_validation :store_body_and_description

  before_validation :update_listing
  has_one :listing, :autosave => true, :dependent => :destroy

  validates_presence_of :body, :u_id

  validates :u_id, :uniqueness => {:scope => :source}


  def store_body_and_description
    self.body = Marshal.dump(self.raw_body)
    if source == "craigslist"
      self.description = self.raw_body["body"]
    elsif source == "zillow"
      noko = Nokogiri::XML(self.raw_body)
      self.description = noko.css("received_description").text
    end
  end

  def set_raw_body
    self.raw_body ||= Marshal.load(self.body) rescue {}
  end

  def update_listing
    self.build_listing if self.listing.nil?
    if self.source == "craigslist" and self.body_type == "JSON"
      self.listing.assign_attributes(self.craigslist_attributes)
    elsif self.source == "zillow" and self.body_type.match(/xml/i)
      self.listing.assign_attributes(self.zillow_attributes)
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
    expired_at = DateTime.strptime(raw["expires"],'%s') rescue nil
    {
      :latitude => raw["location"]["lat"],
      :longitude => raw["location"]["long"],
      :price => raw["price"],
      :bedrooms => three_taps_annotations["bedrooms"],
      :address => raw["location"]["formatted_address"],
      :expired_at => expired_at,
      :timestamp => raw["timestamp"]
    }
  end

  def zillow_attributes
    noko = Nokogiri::XML(self.raw_body)
    expired_at = noko.css("status").text.match(/active/i) ? 1.day.from_now : 1.minute.ago
    {
      :latitude => noko.css("latitude").text,
      :longitude => noko.css("longitude").text,
      :price => noko.css("rent").text,
      :bedrooms => noko.css("bedrooms").text,
      :address => "#{noko.css("address").text} #{noko.css("city").text} #{noko.css("state").text} #{noko.css("zip_code").text}",
      :expired_at => expired_at,
      :user_id => self.user_id
    }
  end

  def self.del_all
    Listing.delete_all
    ListingTag.delete_all
    ListingDetail.delete_all
  end

  def self.quick_import
    require 'importers/zillow_importer'; require 'importers/craigslist_importer'
    ZillowImporter.perform 1
    #CraigslistImporter.perform
  end

  def self.quick_cl
    CraigslistImporter.perform
  end

end
