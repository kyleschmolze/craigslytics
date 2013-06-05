require 'net/http' 

class Analysis < ActiveRecord::Base
  attr_accessible :address, :bedrooms, :latitude, :longitude, :price, :average_price

  geocoded_by :address   # can also be an IP address
  after_validation :geocode          # auto-fetch coordinates
  has_and_belongs_to_many :listings, :order=>:price

  RADIUS = '1'
  API_KEY = '166bb56dcaeba0c3c860981fd50917cd'
  GRAPH_INCR_LARGE = 200
  GRAPH_INCR_SMALL = 50
  after_create :enqueue

  def adjust_min_small(min)
    return min - (min % GRAPH_INCR_SMALL)
  end

  def adjust_min_large(min)
    return min - (min % GRAPH_INCR_LARGE)
  end
  
  def adjust_max_small(max)
    return max + (max % GRAPH_INCR_SMALL)
  end
  
  def adjust_max_large(max)
    return max + (max % GRAPH_INCR_LARGE)
  end

  def adjust_min_smart(min, incr)
    return min - (min % incr)
  end

  def adjust_max_smart(max, incr)
    return max + (max % incr)
  end

  def determine_incr(min, max)
    incr = 50
    while (max-min)/incr > 14
      incr += 50
    end
    return incr
  end

  def listing_min
    return self.listings.first.price
  end
  
  def listing_first_third
    return self.listings[self.listings.length/3].price
  end

  def listing_second_third
    return self.listings[(self.listings.length*2)/3].price
  end

  def listing_max
    return self.listings.last.price
  end

  def average_price_first_third
    listings = self.listings.where("price > ? AND price <= ?", self.listing_min-1, self.listing_first_third)
    total = 0
    for listing in listings do
      total += listing.price
    end
    return total/listings.count
  end
  
  def average_price_second_third
    listings = self.listings.where("price > ? AND price <= ?", self.listing_first_third, self.listing_second_third)
    total = 0
    for listing in listings do
      total += listing.price
    end
    return total/listings.count
  end

  def average_price_third_third
    listings = self.listings.where("price > ? AND price <= ?", self.listing_second_third, self.listing_max)
    total = 0
    for listing in listings do
      total += listing.price
    end
    return total/listings.count
  end

  def average_median
    count = self.listings.count
    middle = count/2
    if count % 2
      return self.listings[middle].price
    else
      return (self.listings[middle].price+self.listings[middle+1].price)/2
    end
  end
  
  def average_median_first_third
    listings = self.listings.where("price > ? AND price <= ?", self.listing_min-1, self.listing_first_third)
    count = listings.count
    middle = count/2 
    if count % 2
      return listings[middle].price
    else
      return (listings[middle].price + listings[middle+1].price)/2
    end
  end
  
  def average_median_second_third
    listings = self.listings.where("price > ? AND price <= ?", self.listing_first_third, self.listing_second_third)
    count = listings.count
    middle = count/2
    if count % 2
      return listings[middle].price
    else
      return (listings[middle].price + listings[middle+1].price)/2
    end
  end

  def average_median_third_third
    listings = self.listings.where("price > ? AND price <= ?", self.listing_second_third, self.listing_max)
    count = listings.count
    middle = count/2 
    if count % 2
      return listings[middle].price
    else
      return (listings[middle].price + listings[middle+1].price)/2
    end
  end

  def get_self_map
    map = "http://maps.google.com/maps/api/staticmap?size=850x200&zoom=auto&center=#{self.latitude},#{self.longitude}&sensor=true&markers=color:red|#{self.latitude},#{self.longitude}"
    return map
  end

  def get_low_map
    markers = "center=#{self.latitude},#{self.longitude}&sensor=true&markers=color:red|#{self.latitude},#{self.longitude}&markers=color:blue|size:mid|" 
    for listing in self.listings.where("price > ? AND price <= ?", self.listing_min-1, self.listing_first_third) do 
      markers += "|#{listing.latitude},#{listing.longitude}" 
    end 
    map = "http://maps.google.com/maps/api/staticmap?size=850x300&zoom=auto&#{markers}"
    if map.length > 1850 
      split = map.split("|") 
      map = split[0].to_s + "|" + split[1].to_s 
      (2..split.length).each do |i| 
        if (map + "|" + split[i].to_s).length < 1850
          map = map + "|" + split[i].to_s 
        else 
          break 
        end 
      end 
    end 
    return map
  end
  
  def get_middle_map
    markers = "center=#{self.latitude},#{self.longitude}&sensor=true&markers=color:red|#{self.latitude},#{self.longitude}&markers=color:blue|size:mid|" 
    for listing in self.listings.where("price > ? AND price <= ?", self.listing_first_third, self.listing_second_third) do 
      markers += "|#{listing.latitude},#{listing.longitude}" 
    end 
    map = "http://maps.google.com/maps/api/staticmap?size=850x300&zoom=auto&#{markers}"
    if map.length > 1850 
      split = map.split("|") 
      map = split[0].to_s + "|" + split[1].to_s 
      (2..split.length).each do |i| 
        if (map + "|" + split[i].to_s).length < 1850
          map = map + "|" + split[i].to_s 
        else 
          break 
        end 
      end 
    end 
    return map
  end

  def get_high_map
    markers = "center=#{self.latitude},#{self.longitude}&sensor=true&markers=color:red|#{self.latitude},#{self.longitude}&markers=color:blue|size:mid|" 
    for listing in self.listings.where("price > ? AND price <= ?", self.listing_second_third, self.listing_max) do 
      markers += "|#{listing.latitude},#{listing.longitude}" 
    end 
    map = "http://maps.google.com/maps/api/staticmap?size=850x300&zoom=auto&#{markers}"
    if map.length > 1850 
      split = map.split("|") 
      map = split[0].to_s + "|" + split[1].to_s 
      (2..split.length).each do |i| 
        if (map + "|" + split[i].to_s).length < 1850
          map = map + "|" + split[i].to_s 
        else 
          break 
        end 
      end 
    end 
    return map
  end

  def get_listings_map
    markers = "center=#{self.latitude},#{self.longitude}&sensor=true&markers=color:blue|size:mid|" 
    for listing in self.listings do 
      markers += "|#{listing.latitude},#{listing.longitude}" 
    end 
    map = "http://maps.google.com/maps/api/staticmap?size=850x300&zoom=auto&#{markers}"
    if map.length > 1850 
      split = map.split("|") 
      map = split[0].to_s + "|" + split[1].to_s 
      (2..split.length).each do |i| 
        if (map + "|" + split[i].to_s).length < 1850
          map = map + "|" + split[i].to_s 
        else 
          break 
        end 
      end 
    end 
    return map + "&markers=color:red|#{self.latitude},#{self.longitude}"
  end

  def average_pictures
    count = 0
    for listing in self.listings do
      count += listing.info["images"].count if listing.info["images"].present?
    end
    return count/(self.listings.count)
  end

  def average_pictures_first_third
    count = 0
    listings = self.listings.where("price > ? AND price <= ?", self.listing_min-1, self.listing_first_third) 
    for listing in listings 
      count += listing.info["images"].count if listing.info["images"].present?
    end
    return count/(listings.count)
  end

  def average_pictures_second_third
    count = 0
    listings = self.listings.where("price > ? AND price <= ?", self.listing_first_third, self.listing_second_third) 
    for listing in listings do 
      count += listing.info["images"].count if listing.info["images"].present?
    end
    return count/(listings.count)
  end

  def average_pictures_third_third
    count = 0
    listings = self.listings.where("price > ? AND price <= ?", self.listing_second_third, self.listing_max) 
    for listing in listings
      count += listing.info["images"].count if listing.info["images"].present?
    end
    return count/(listings.count)
  end

  def pictures_first_third
    images = []
    for listing in self.listings.where("price > ? AND price <= ?", self.listing_min-1, self.listing_first_third) do 
      images << listing.info["images"].first["full"] if listing.info["images"].present?
    end
    return images.uniq {|i| i.gsub(/https?:\/\//, '').gsub(/^.*\//, '') }
  end

  def pictures_second_third
    images = []
    for listing in self.listings.where("price > ? AND price <= ?", self.listing_first_third, self.listing_second_third) do 
      images << listing.info["images"].first["full"] if listing.info["images"].present?
    end
    return images.uniq {|i| i.gsub(/https?:\/\//, '').gsub(/^.*\//, '') }
  end

  def pictures_third_third
    images = []
    for listing in self.listings.where("price > ? AND price <= ?", self.listing_second_third, self.listing_max) do
      images << listing.info["images"].first["full"] if listing.info["images"].present?
    end
    return images.uniq {|i| i.gsub(/https?:\/\//, '').gsub(/^.*\//, '') }
  end

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
        num_pages = (num_matches/100)+1 if num_matches > 100
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
    if Rails.env.production? 
      Resque.enqueue Analysis, self.id
    else
      Analysis.perform(self.id)
    end
  end
  
  def self.perform(analysis_id)
    analysis = Analysis.find analysis_id
    analysis.analyze_and_store
    analysis.processed = true
    analysis.save!
  end
end
