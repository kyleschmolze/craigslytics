require 'net/http' 

class CraigslistImporter
  attr_accessor :listing_importer, :listing_import

  @queue = :importing

  def import(importer)
    self.listing_importer = importer
    metro = "#{self.listing_importer.metro}".upcase

    self.listing_import = ListingImport.create(listing_importer_id: self.listing_importer.id)

    listing = Listing.where(user_id: nil).order('timestamp DESC').first
    timestamp = listing ? (listing.timestamp - 3.hours.to_i) : (DateTime.now - 3.hour).to_i
    anchor = get_anchor(timestamp)


    response = poll(anchor, metro)
    while response["postings"].present? do
      
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
    response = JSON.parse(res.body)
    if response["success"]
      puts "    success!"
      return response
    else
      throw "In poll: #{response["error"]}"
    end
  end

  def save_listings(postings, source, type)
    for posting in postings do
      u_id = posting["id"].to_s

      detail = ListingDetail.where(source: source, u_id: u_id).first_or_initialize

      new = detail.new_record?

      current_date = DateTime.strptime(posting["timestamp"], '%s') rescue nil
      self.listing_import.update_column(:current_date, current_date) if current_date

      ids = ["361479069", "361479091", "361479097", "361479223", "361479293", "361479833", "361479989", "361480175", "361480179", "361480181", "361480511", "361480878", "361480930", "361480931", "361480933", "361480935", "361480946", "361480962", "361480965", "361480975", "361481050", "361481063", "361481077", "361481085", "361481130", "361481162", "361481163", "361481165", "361481173", "361481206", "361481208", "361481212", "361481218", "361481220", "361481222", "361481223", "361481374", "361481563", "361485935", "361486907", "361487227", "361526966", "361527067", "361527074", "361527145", "361527207", "361527246", "361527605", "361527606", "361527741", "361528349", "361528644", "361528648", "361528678", "361528731", "361528905", "361529021", "361529104", "361529156", "361529789", "361529791", "361529800", "361563155", "361595120", "361626932", "361627047", "361627476", "361627924", "361628654", "361628694", "361629752", "361630167", "361674629", "361678937", "361683054", "361685834", "361735927", "361735984", "361735990", "361736100", "361736107", "361736126", "361736186", "361736216", "361736351", "361736432", "361736436", "361736443", "361736448", "361736509", "361736608", "361736892", "361737299", "361737327", "361737455", "361737519", "361737589", "361737655", "361737866", "361737929", "361738030", "361738137", "361738149", "361738558", "361739640", "361739709", "361739729", "361740069", "361740329", "361740356", "361740443", "361740522", "361741925", "361756950", "361783897", "361834821", "361835032", "361840270", "361840294", "361840296", "361840302", "361846721", "361847601", "361848010", "361848512", "361849173", "361849571", "361849750", "361850212", "361850616", "361850713", "361850772", "361850820", "361851093", "361851248", "361851263", "361851264", "361851300", "361851343", "361851816", "361851970", "361851999", "361852083", "361852100", "361852101", "361852160", "361852274", "361852960", "361853869", "361853973", "361854049", "361854062", "361854133", "361854168", "361854217", "361854262", "361854266", "361854276", "361854286", "361854526", "361854867", "361854932", "361855256", "361855477", "361855496", "361855684", "361856068", "361856875", "361856939", "361894814", "361911114", "361974218", "361990942", "361995331", "361632932", "361739791", "361740058", "361851257"]



      if detail.update_attributes(raw_body: posting, body_type: type)
        if new
          self.listing_import.increment!(:new_listings, 1)
        else
          self.listing_import.increment!(:updated_listings, 1)
        end
        if ids.include? detail.u_id
          throw "INCORRECTLY DID SAVE"
        end
      else
        if ids.include? detail.u_id
          throw "CORRECTLY DID NOT SAVE"
        end
        self.listing_import.increment!(:failed_listings, 1)
        puts detail.errors.full_messages
      end
    end
  end

end
