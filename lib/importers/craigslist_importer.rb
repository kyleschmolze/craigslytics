require 'net/http' 

class CraigslistImporter
  attr_accessor :listing_importer, :listing_import

  @queue = :importing

  def import(importer)
    self.listing_importer = importer
    metro = "#{self.listing_importer.metro}".upcase

    self.listing_import = ListingImport.create(listing_importer_id: self.listing_importer.id)

    listing = Listing.where(user_id: nil).order('timestamp DESC').first
    timestamp = listing ? (listing.timestamp - 5.minute.to_i) : DateTime.parse("Jun 1, 2013").to_i

    anchor = get_anchor(timestamp)


    response = poll(anchor, metro)
    while response["postings"].present? and response["anchor"].present? do
      
      self.listing_import.update_column(:current_anchor, anchor)
      postings = response["postings"]
      save_listings(postings, "craigslist", "JSON")
      anchor = response["anchor"]
      response = poll(anchor, metro)
    end
    self.listing_import.update_column(:completed_at, DateTime.now)
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
    params = "/poll/?metro=#{metro}&anchor=#{anchor}&category=RHFR&retvals=id,account_id,source,category,category_group,location,external_id,external_url,heading,body,html,timestamp,expires,language,price,currency,images,annotations,status,immortal&source=CRAIG&auth_token=#{self.listing_importer.api_key}"
    req = Net::HTTP::Get.new(url.to_s + params)
    puts "    request: #{url.to_s + params}"
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    if res.code == "200"   # only covers HTTPOK class.  see http://ruby-doc.org/stdlib-2.0/libdoc/net/http/rdoc/Net/HTTP.html
      response = JSON.parse(res.body)
      if response["success"]
        puts "    success!"
        return response
      else
        throw "In poll: #{response["error"]}"
      end
    else
      throw "In poll: HTTP code: #{res.code}"
    end
  end

  def save_listings(postings, source, type)
    for posting in postings do
      u_id = posting["id"].to_s

      detail = ListingDetail.where(source: source, u_id: u_id).first_or_initialize

      new = detail.new_record?

      current_date = DateTime.strptime(posting["timestamp"], '%s') rescue nil
      self.listing_import.update_column(:current_date, current_date) if current_date


      if detail.update_attributes(raw_body: posting, body_type: type)
        if new
          self.listing_import.increment!(:new_listings, 1)
        else
          self.listing_import.increment!(:updated_listings, 1)
        end
      else
        self.listing_import.increment!(:failed_listings, 1)
        puts detail.errors.full_messages
      end
    end
  end

end
