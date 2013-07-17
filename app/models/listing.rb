class Listing < ActiveRecord::Base
  attr_accessible :address, :bedrooms, :latitude, :longitude, :price, :analysis_id, 
                  :dogs, :cats, :listing_detail_id, :user_id, :timestamp, :expired_at

  has_many :listing_tags 
  has_many :tags, through: :listing_tags
  has_and_belongs_to_many :analyses
  belongs_to :listing_detail
  validates_presence_of :price, :bedrooms, :latitude, :longitude
  geocoded_by :address

  after_create :generate_tags

  #url of a static google map of the analyzed listing
  def get_self_map
    map = "http://maps.google.com/maps/api/staticmap?size=450x450&zoom=auto&center=#{self.latitude},#{self.longitude}&sensor=true&markers=color:blue|#{self.latitude},#{self.longitude}"
    return map
  end

  def pictures
    if self.listing_detail.source == "craigslist"
      pics = self.listing_detail.raw_body["images"][0]
      if pics.present?
        pics = pics.map{|p| p["full"]} 
        pics = pics.uniq {|i| i.gsub(/https?:\/\//, '').gsub(/^.*\//, '') }
      end
      return pics
    elsif self.listing_detail.source == "ygl"
      noko = Nokogiri::XML(self.listing_detail.raw_body)
      pics = noko.css("Photo")
      if !pics.blank?
        pics = pics.map{|p| p.text}
        pics = pics.uniq {|i| i.gsub(/https?:\/\//, '').gsub(/^.*\//, '') }
      end
      return pics
    elsif self.listing_detail.source == "zillow"
      noko = Nokogiri::XML(self.listing_detail.raw_body)
      pics = noko.css("original")
      if !pics.blank?
        pics = pics.map{|p| p.text}
        pics = pics.uniq {|i| i.gsub(/https?:\/\//, '').gsub(/^.*\//, '') }
      end
      return pics
    else
      return []
    end
  end

  def self.parse_all
    Listing.find_each do |listing|
      listing.parse
      listing.save
      listing.tags.delete_all
      listing.generate_tags
    end
  end

  def self.generate_all
    Listing.find_each do |listing|
      listing.generate_tags
    end
  end

  def self.clear_tags
    Listing.find_each do |listing|
      listing.tags.destroy_all
    end
  end

  def clear_tags
    self.tags.destroy_all
  end

  def self.clear_and_generate
    Listing.clear_tags
    Listing.generate_all
  end

  def generate_tags 
    Tag.all.each do |t|
      if t.category == "unit_type"
        t.assign_unit_type self 
      end
      if self.listing_detail.source == "craigslist"
        t.detect_in_listing self
      elsif self.listing_detail.source == "zillow"
        t.zillow_extract_field self
      elsif self.listing_detail.source == "ygl"
        t.ygl_extract_field self
      end
    end
  end


  # returns string "townhouse > condo" 
  def unit_type
    arr = []
    self.tags.each do |t|
      if t.category == "unit_type"
        arr[t.complexity] = t.display
      end
    end
    str = ""
    for i in (2..3) do 
      if i == 2
        str += arr[i] if arr[i]
      else
        str += " " + arr[i] if arr[i]
      end
    end
    return str
  end

  def first_parse
    if self.new_record?
      self.parse
    end
  end

  def create_comparison_with(a_listing, options)
    if options 
      # WEIGHTS
      address_weight    = options[:address_weight].to_f
      bedrooms_weight   = options[:bedrooms_weight].to_f
      location_weight   = options[:location_weight].to_f
      price_weight      = options[:price_weight].to_f

    end
    # check presence of weights
    if address_weight.blank? 
      address_weight = bedrooms_weight = location_weight = price_weight = 1
    end


    address_score = (address_weight * (self.address == a_listing.address ? 0 : 1))
    bedrooms_score = (bedrooms_weight * (self.bedrooms - a_listing.bedrooms)**2)
    location_score = location_weight * (((self.latitude - a_listing.latitude)**2) + 
                                        ((self.longitude - a_listing.longitude)**2) **0.5)
    price_score = (price_weight * (self.price - a_listing.price)**2) 
    diff_squared = address_score + bedrooms_score + location_score + price_score

    # If the comparison exists, update it's score, else create it

    if l = ListingComparison.where({:listing_1_id=>self.id, :listing_2_id=>a_listing.id}).first
      l.score = diff_squared
      l.address_score = address_score
      l.bedrooms_score = bedrooms_score
      l.location_score = location_score
      l.price_score = price_score
      l.save
    elsif l = ListingComparison.where({:listing_1_id=>a_listing.id, :listing_2_id=>self.id}).first
      l.score = diff_squared
      l.address_score = address_score
      l.bedrooms_score = bedrooms_score
      l.location_score = location_score
      l.price_score = price_score
      l.save
    else
      ListingComparison.create({:listing_1_id=>self.id, :listing_2_id=>a_listing.id, :score=>diff_squared, 
                               :address_score=>address_score, :bedrooms_score=>bedrooms_score, :location_score=>location_score, 
                               :price_score=>price_score})
    end
  end

  def self.generate_all_comparisons(options)
    Listing.all.each do |i|
      Listing.all.each do |j|
        i.create_comparison_with(j, options)
      end
    end
  end

  # tested with 7 listings, should create 7 choose 2 or 21 listing_comparisons, successful


end
