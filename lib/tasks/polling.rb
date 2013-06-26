require 'net/http' 

class Polling

  API_KEY = '166bb56dcaeba0c3c860981fd50917cd'

  def self.get_anchor(timestamp)
    puts "Getting Anchor --"
    puts "    timestamp: #{timestamp}"
    url = URI.parse("http://polling.3taps.com")
    params = "/anchor/?timestamp=#{timestamp}&auth_token=#{API_KEY}"
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

  def self.poll(anchor, metro)
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

  def self.save_listings(postings, source, type)
    puts "Saving Listings --"
    counter = 1
    for posting in postings do
      puts "    #{counter}/#{postings.count}"
      counter += 1
      l = ListingDetail.create(raw_body: posting, body_type: type, source: source)
      if l.errors.any?
        puts l.errors.full_messages
      end
    end
  end

  def self.three_taps(metro, datetime)
    metro = metro.upcase
    timestamp = datetime.to_i
    anchor = get_anchor(timestamp)
    response = poll(anchor, metro)
    while response["postings"].present? do
      postings = response["postings"]
      save_listings(postings, "craigslist", "JSON")
      anchor = response["anchor"]
      response = poll(anchor, metro)
    end
  end

end
