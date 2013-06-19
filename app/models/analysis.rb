require 'net/http' 

class Analysis < ActiveRecord::Base
  attr_accessible :address, :bedrooms, :latitude, :longitude, :price, :average_price

  geocoded_by :address   # can also be an IP address
  after_validation :geocode, :if => :lat_lng_blank?          # auto-fetch coordinates
  has_and_belongs_to_many :listings, :order=>:price

  API_KEY = '166bb56dcaeba0c3c860981fd50917cd'
  INITIAL_RADIUS = "2"
  after_create :enqueue

  def lat_lng_blank?
    return (latitude.blank? or longitude.blank?)
  end

  def get_segments
    segments = []
    segments << get_segment(min_listing_price-1, first_tertile)
    segments << get_segment(first_tertile, second_tertile)
    segments << get_segment(second_tertile, max_listing_price)
    return segments
  end

  def get_segment(min, max)
    if min == max
      return Segment.new(self.listings.where(:price => max)) 
    else
      return Segment.new(self.listings.where("price > ? AND price <= ?", min, max)) 
    end
  end

  def get_overview
    return Segment.new(self.listings)
  end

  #listing_min
  def min_listing_price
    return self.listings.first.price
  end
  
  #listing_first_third
  def first_tertile
    prices = self.listings.map(&:price).uniq
    return prices[prices.length/3]
  end

  #listing_second_third
  def second_tertile
    prices = self.listings.map(&:price).uniq
    return prices[(prices.length*2)/3]
  end

  #listing_max
  def max_listing_price
    return self.listings.last.price
  end

  #url of a static google map of the analyzed listing
  def get_self_map
    map = "http://maps.google.com/maps/api/staticmap?size=650x300&zoom=auto&center=#{self.latitude},#{self.longitude}&sensor=true&markers=color:red|#{self.latitude},#{self.longitude}"
    return map
  end

  def search_3taps
    url = URI.parse("http://search.3taps.com")
    params = "?rpp=100&lat=#{self.latitude}&long=#{self.longitude}&radius=#{self.radius}mi&category=RHFR&retvals=id,account_id,source,category,category_group,location,external_id,external_url,heading,body,html,timestamp,expires,language,price,currency,images,annotations,status,immortal&annotations={bedrooms:#{self.bedrooms}br}&source=CRAIG&auth_token=#{API_KEY}"
    req = Net::HTTP::Get.new(url.to_s + params)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    response = JSON.parse(res.body)
    return response
  end

  def save_listings(postings)
    puts "saving listings"
    puts "#{postings.count}"
    for posting in postings do
      puts "here"
      if Listing.where(:u_id => posting["id"]).present? 
        puts "listing exists!"
        self.listings << Listing.where(:u_id => posting["id"]) 
      else
        puts "listing is new!"
        l = self.listings.create(info: posting)
        if l.errors.any?
          puts l.errors.full_messages
        end
      end
    end
  end

  #scrapes 3-taps data and stores all similar listings
  def analyze_and_store
    if self.radius.blank?
      self.radius = INITIAL_RADIUS
      puts "Starting Analysis"
      puts "Initial radius, #{INITIAL_RADIUS}"
      puts "Starting Search"
    end
    puts self.radius
    response = self.search_3taps
    if response["success"]
      puts "Success"
      anchor = response["anchor"] 
      num_matches = response["num_matches"]
      if !(num_matches < 20 or num_matches == nil)
        puts "Goin"
        puts "Polling 3taps, tier: 0 page: 0"
        next_page = response["next_page"]
        next_tier = response["next_tier"]
        puts "Next_page: #{next_page}"
        puts "Next_tier: #{next_tier}"
        self.save_listings(response["postings"])
        while (next_tier != -1) do 
          puts "Polling 3taps, tier: #{next_tier} page: #{next_page}"
          url = URI.parse("http://search.3taps.com")
          params = "?rpp=100&lat=#{self.latitude}&long=#{self.longitude}&radius=#{self.radius}mi&category=RHFR&retvals=id,account_id,source,category,category_group,location,external_id,external_url,heading,body,html,timestamp,expires,language,price,currency,images,annotations,status,immortal&annotations={bedrooms:#{self.bedrooms}br}&anchor=#{anchor}&page=#{next_page}&tier=#{next_tier}&source=CRAIG&auth_token=#{API_KEY}"
          req = Net::HTTP::Get.new(url.to_s + params)
          res = Net::HTTP.start(url.host, url.port) {|http|
            http.request(req)
          }
          response = JSON.parse(res.body)
          if response["success"]
            self.save_listings(response["postings"])
          else
            self.update_column :processed, true
            self.update_column :failed, true
            throw response["error"]
          end
          next_page = response["next_page"]
          next_tier = response["next_tier"]
        end
      else
        if self.radius < (INITIAL_RADIUS.to_i + 10)
          puts "Not enough listings. Increasing radius"
          self.radius += 1
          puts "Radius is now #{self.radius} miles"
          self.analyze_and_store
        else
          puts "Not enough listings found!"
        end
      end
    else
      self.update_column :processed, true
      self.update_column :failed, true
      throw response["error"]
    end
  end

  @queue = :analysis

  def enqueue
    if Rails.env.production?
      Resque.enqueue Analysis, self.id
    else
      self.analyze_and_store
      self.processed = true
      self.save!
    end
  end
  
  def self.perform(analysis_id)
    analysis = Analysis.find analysis_id
    begin
      analysis.analyze_and_store
      analysis.processed = true
      analysis.save!
    rescue => e
      analysis.update_column :processed, true
      analysis.update_column :failed, true
      throw e
    end
  end
end
