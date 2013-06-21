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

  def self.poll(anchor, state)
    puts "Polling 3taps --"
    puts "    anchor: #{anchor}"
    puts "    state: #{state}"
    url = URI.parse("http://polling.3taps.com")
    params = "/poll/?state=#{state}&anchor=#{anchor}&category=RHFR&retvals=id,account_id,source,category,category_group,location,external_id,external_url,heading,body,html,timestamp,expires,language,price,currency,images,annotations,status,immortal&source=CRAIG&auth_token=#{API_KEY}"
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

  def self.save_listings(postings)
    puts "Saving Listings --"
    counter = 1
    for posting in postings do
      puts "    #{counter}/#{postings.count}"
      counter += 1
      if Listing.where(:u_id => posting["id"]).present? 
        puts "    listing exists!"
      else
        puts "    listing is new!"
        l = Listing.create(info: posting)
        if l.errors.any?
          puts l.errors.full_messages
        end
      end
    end
  end

  def self.three_taps(state, datetime)
    state = state.upcase
    timestamp = datetime.to_i
    anchor = get_anchor(timestamp)
    response = poll(anchor, state)
    while response["postings"].present? do
      postings = response["postings"]
      save_listings(postings)
      anchor = response["anchor"]
      response = poll(anchor, state)
    end
  end

end
