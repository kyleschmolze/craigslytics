require 'net/http' 

class Listing < ActiveRecord::Base
  attr_accessible :address, :bedrooms, :latitude, :longitude, :price

  geocoded_by :address   # can also be an IP address
  after_validation :geocode          # auto-fetch coordinates

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
    url = URI.parse("http://search.3taps.com")
    params = "?rpp=100&lat=#{self.latitude}&long=#{self.longitude}&radius=#{radius}mi&category=RHFR&retvals=price&annotations={bedrooms:#{self.bedrooms}br}&source=CRAIG&auth_token=166bb56dcaeba0c3c860981fd50917cd"
    req = Net::HTTP::Get.new(url.to_s + params)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    response = JSON.parse(res.body)
    if response["success"]
      anchor = response["anchor"]
      num_matches = response["num_matches"]
      return "Not enough data for analysis" if (num_matches == 0 or num_matches == nil)
      num_pages = 1
      num_pages = num_matches/100 if num_matches > 100
      total_price = 0
      (0..num_pages-1).each do |i|
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
      return "On #{DateTime.now.strftime("%a, %b %d %Y at %I:%M%p")}, there were #{num_matches} similar listings in a #{radius} mile radius. The average price of the listings was $#{total_price/num_matches}. You can view some of the listings in the table below."
    else
      return "Not enough data for analysis"
    end
  end

  def create_comparison_with(a_listing)
    
    # WEIGHTS
    address_weight    = 1 
    bedrooms_weight   = 1 
    latitude_weight  = 1
    longitude_weight = 1
    price_weight      = 1

    diff_squared = (address_weight * (self.address == a_listing.address ? 1 : 0))    + 
                   (bedrooms_weight * (self.bedrooms - a_listing.bedrooms)**2)       + 
                   (latitude_weight * (self.latitude - a_listing.latitude)**2)    +
                   (longitude_weight * (self.longitude - a_listing.longitude)**2) +
                   (price_weight * (self.price - a_listing.price)**2) 
    
    ListingComparison.new({:listing_1_id=>self.id, :listing_2_id=>a_listing.id, :score=>diff_squared})

  end

end
