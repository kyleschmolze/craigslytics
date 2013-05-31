require 'net/http' 

class Analysis < ActiveRecord::Base
  attr_accessible :address, :bedrooms, :latitude, :longitude, :price

  geocoded_by :address   # can also be an IP address
  after_validation :geocode          # auto-fetch coordinates

  after_create :enqueue

  def get_similar_listings(radius)
    url = URI.parse("http://search.3taps.com")
    params = "?rpp=100&lat=#{self.latitude}&long=#{self.longitude}&radius=#{radius}mi&category=RHFR&retvals=price,heading,external_url&annotations={bedrooms:#{self.bedrooms}br}&source=CRAIG&sort=price&auth_token=166bb56dcaeba0c3c860981fd50917cd"
    req = Net::HTTP::Get.new(url.to_s + params)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    response = JSON.parse(res.body)
    return response["postings"]
  end

  def get_analytics(radius)
    p "0"
    url = URI.parse("http://search.3taps.com")
    params = "?rpp=100&lat=#{self.latitude}&long=#{self.longitude}&radius=#{radius}mi&category=RHFR&retvals=price&annotations={bedrooms:#{self.bedrooms}br}&source=CRAIG&auth_token=166bb56dcaeba0c3c860981fd50917cd"
    req = Net::HTTP::Get.new(url.to_s + params)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    p "1"
    response = JSON.parse(res.body)
    if response["success"]
    p "2"
      anchor = response["anchor"]
      num_matches = response["num_matches"]
      return "Not enough data for analysis" if (num_matches == 0 or num_matches == nil)
      num_pages = 1
      num_pages = num_matches/100 if num_matches > 100
      total_price = 0
      (0..num_pages-1).each do |i|
    p "4"
        url = URI.parse("http://search.3taps.com")
        params = "?rpp=100&lat=#{self.latitude}&long=#{self.longitude}&radius=#{radius}mi&category=RHFR&retvals=price&annotations={bedrooms:#{self.bedrooms}br}&anchor=#{anchor}&page=#{i}&source=CRAIG&auth_token=166bb56dcaeba0c3c860981fd50917cd"
        req = Net::HTTP::Get.new(url.to_s + params)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }
        response = JSON.parse(res.body)
        for posting in response["postings"] 
          total_price += posting["price"].to_i
        end
      end
      return "On #{DateTime.now.strftime("%a, %b %d %Y at %I:%M%p")}, there were #{num_matches} similar listings in a #{radius} mile radius. The average price of the listings was $#{total_price/num_matches}. You can view some of the lisitings in the table below."
    else
      return "Not enough data for analysis"
    end
  end

  @queue = :analysis

  def enqueue
    Resque.enqueue Analysis, self.id
  end
  
  def self.perform(analysis_id)
    p "Processing analysis #{analysis_id}"
    analysis = Analysis.find analysis_id
    analysis.update_column :processed, true
  end
end
