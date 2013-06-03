require 'net/http' 

class Analysis < ActiveRecord::Base
  attr_accessible :address, :bedrooms, :latitude, :longitude, :price, :average_price

  geocoded_by :address   # can also be an IP address
  after_validation :geocode          # auto-fetch coordinates
  has_and_belongs_to_many :listings 

  RADIUS = '2'
  API_KEY = '166bb56dcaeba0c3c860981fd50917cd'
  after_create :enqueue

  def analyze_and_store
    url = URI.parse("http://search.3taps.com")
    params = "?rpp=100&lat=#{self.latitude}&long=#{self.longitude}&radius=#{RADIUS}mi&category=RHFR&retvals=id,account_id,source,category,category_group,location,external_id,external_url,heading,body,html,timestamp,expires,language,price,currency,images,annotations,status,immortal&annotations={bedrooms:#{self.bedrooms}br}&source=CRAIG&auth_token=#{API_KEY}"
    req = Net::HTTP::Get.new(url.to_s + params)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    response = JSON.parse(res.body)
    if response["success"]
      anchor = response["anchor"]
      num_matches = response["num_matches"]
      if !(num_matches == 0 or num_matches == nil)
        num_pages = 1
        num_pages = num_matches/100 if num_matches > 100
        total_price = 0
        (0..num_pages-1).each do |i|
          url = URI.parse("http://search.3taps.com")
          params = "?rpp=100&lat=#{self.latitude}&long=#{self.longitude}&radius=#{RADIUS}mi&category=RHFR&retvals=id,account_id,source,category,category_group,location,external_id,external_url,heading,body,html,timestamp,expires,language,price,currency,images,annotations,status,immortal&annotations={bedrooms:#{self.bedrooms}br}&anchor=#{anchor}&page=#{i}&source=CRAIG&auth_token=#{API_KEY}"
          req = Net::HTTP::Get.new(url.to_s + params)
          res = Net::HTTP.start(url.host, url.port) {|http|
            http.request(req)
          }
          response = JSON.parse(res.body)
          for posting in response["postings"] 
            total_price += posting["price"].to_i
            self.listings.create(latitude: posting["location"]["lat"], 
                           longitude: posting["location"]["long"], 
                           price: posting["price"], 
                           bedrooms: posting["annotations"]["bedrooms"][0],
                           address: posting["location"]["formatted_address"],
                           info: posting)
          end
        end
      end
      self.average_price = total_price/num_matches
    end
  end

  @queue = :analysis

  def enqueue
    Resque.enqueue Analysis, self.id
  end
  
  def self.perform(analysis_id)
    analysis = Analysis.find analysis_id
    analysis.analyze_and_store
    analysis.processed = true
    analysis.save!
  end
end
