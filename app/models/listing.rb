require 'net/http' 

class Listing < ActiveRecord::Base
  attr_accessible :address, :bedrooms, :latitude, :longitude, :price

  def get_analytics
    url = URI.parse("http://search.3taps.com")
    params = "?rpp=100&lat=#{self.latitude}&long=#{self.longitude}&radius=2mi&category=RHFR&retvals=price,heading,body&annotations={bedrooms:#{self.bedrooms}br}"
    req = Net::HTTP::Get.new(url.to_s + params)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    response = JSON.parse(res.body)
    anchor = response["anchor"]
    num_matches = response["num_matches"]
    num_pages = 1
    num_pages = num_matches/100 if num_matches > 100
    total_price = 0
    (0..num_pages-1).each do |i|
      url = URI.parse("http://search.3taps.com")
      params = "?rpp=100&lat=#{self.latitude}&long=#{self.longitude}&radius=2mi&category=RHFR&retvals=price,heading,body&annotations={bedrooms:#{self.bedrooms}br}&anchor=#{anchor}&page=#{i}"
      req = Net::HTTP::Get.new(url.to_s + params)
      res = Net::HTTP.start(url.host, url.port) {|http|
        http.request(req)
      }
      response = JSON.parse(res.body)
      for posting in response["postings"] 
        total_price += posting["price"]
      end
    end
    return total_price/num_matches
  end

end
