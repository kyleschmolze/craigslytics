require 'net/http' 

class CraigslistImporter
  attr_accessor :listing_importer

  @queue = :importing

  API_KEY = '166bb56dcaeba0c3c860981fd50917cd'

  def import(importer)
    self.listing_importer = importer
    metro = "#{self.listing_importer.metro}".upcase

    listing = Listing.where(user_id: nil).order('timestamp DESC').first
    timestamp = listing ? listing.timestamp : (DateTime.now - 2.hour).to_i
    anchor = get_anchor(timestamp)

    response = poll(anchor, metro)
    while response["postings"].present? do
      postings = response["postings"]
      save_listings(postings, "craigslist", "JSON")
      anchor = response["anchor"]
      response = poll(anchor, metro)
    end
  end

  def get_anchor(timestamp)
    puts "Getting Anchor --"
    puts "    timestamp: #{timestamp}"
    url = URI.parse("http://polling.3taps.com")
    params = "/anchor/?timestamp=#{timestamp}&auth_token=#{self.listing_importer.api_key}"
    req = Net::HTTP::Get.new(url.to_s + params)
    puts "    request: #{url.to_s + params}"
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    response = JSON.parse(res.body)
    if response["success"]
      puts "    success!"
      puts "    anchor is #{response["anchor"]}..."
      return response["anchor"]
    else
      throw "In get_anchor: #{response["error"]}"
    end
  end

  def poll(anchor, metro)
    puts "Polling 3taps --"
    puts "    anchor: #{anchor}"
    puts "    metro: #{metro}"
    url = URI.parse("http://polling.3taps.com")
    params = "/poll/?metro=#{metro}&anchor=#{anchor}&category=RHFR&retvals=id,account_id,source,category,category_group,location,external_id,external_url,heading,body,html,timestamp,expires,language,price,currency,images,annotations,status,immortal&source=CRAIG&auth_token=#{API_KEY}"
    req = Net::HTTP::Get.new(url.to_s + params)
    puts "    request: #{url.to_s + params}"
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    response = JSON.parse(res.body)
    if response["success"]
      puts "    success!"
      return response
    else
      throw "In poll: #{response["error"]}"
    end
  end

  def save_listings(postings, source, type)
    puts "Saving Listings --"
    counter = 1
    for posting in postings do
      puts "    #{counter}/#{postings.count}"
      counter += 1
      l = ListingDetail.where(source: source, u_id: posting["id"]).first_or_initialize
      if !l.update_attributes(raw_body: posting, body_type: type)
        puts l.errors.full_messages
      end
    end
  end

end
