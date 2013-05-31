require 'net/http' 

class Listing < ActiveRecord::Base
  attr_accessible :address, :bedrooms, :latitude, :longitude, :price

  geocoded_by :address   # can also be an IP address
  after_validation :geocode          # auto-fetch coordinates

  def get_similar_listings(radius)
    url = URI.parse("http://search.3taps.com")
    params = "?rpp=100&lat=#{self.latitude}&long=#{self.longitude}&radius=#{radius}mi&category=RHFR&retvals=price,heading,external_url&annotations={bedrooms:#{self.bedrooms}br}&source=CRAIG&sort=price"
    req = Net::HTTP::Get.new(url.to_s + params)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    response = JSON.parse(res.body)
    return response["postings"]
  end

  def get_analytics(radius)
    url = URI.parse("http://search.3taps.com")
    params = "?rpp=100&lat=#{self.latitude}&long=#{self.longitude}&radius=#{radius}mi&category=RHFR&retvals=price&annotations={bedrooms:#{self.bedrooms}br}&source=CRAIG"
    req = Net::HTTP::Get.new(url.to_s + params)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    response = JSON.parse(res.body)
    anchor = response["anchor"]
    num_matches = response["num_matches"]
    return "Not enough data for analysis" if (num_matches == 0 or num_matches == nil)
    num_pages = 1
    num_pages = num_matches/100 if num_matches > 100
    total_price = 0
    (0..num_pages-1).each do |i|
      url = URI.parse("http://search.3taps.com")
      params = "?rpp=100&lat=#{self.latitude}&long=#{self.longitude}&radius=#{radius}mi&category=RHFR&retvals=price&annotations={bedrooms:#{self.bedrooms}br}&anchor=#{anchor}&page=#{i}&source=CRAIG"
      req = Net::HTTP::Get.new(url.to_s + params)
      res = Net::HTTP.start(url.host, url.port) {|http|
        http.request(req)
      }
      response = JSON.parse(res.body)
      for posting in response["postings"] 
        total_price += posting["price"]
      end
    end
    return "On #{DateTime.now.strftime("%a, %b %d %Y at %I:%M%p")}, there were #{num_matches} similar listings in a #{radius} mile radius. The average price of the listings was $#{total_price/num_matches}. You can view some of the lisitings in the table below."
  end

end