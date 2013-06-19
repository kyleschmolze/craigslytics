class Segment
  attr_reader :listings, :median, :pictures, :average_pictures, :min_price, :max_price, :increment,
    :adjusted_min, :adjusted_max, :unique_id

  def initialize(listings)
    @listings = listings
    len = @listings.count
    @median = (@listings[(len - 1) / 2].price + @listings[len / 2].price) / 2 
    @pictures = []
    count = 0
    for listing in @listings do 
      if listing.info["images"].present?
        @pictures << listing.info["images"].sample["full"]
        count += listing.info["images"].count 
      end
    end
    @pictures = @pictures.uniq {|i| i.gsub(/https?:\/\//, '').gsub(/^.*\//, '') }
    @average_pictures = count/len 
    @min_price = @listings.first.price
    @max_price = @listings.last.price
    @increment = 50
    while (@max_price - @min_price)/@increment > 14
      @increment += 50
    end
    @adjusted_min = @min_price - (@min_price % @increment)
    @adjusted_max = @max_price + (@max_price % @increment)
    @unique_id = SecureRandom.uuid
  end

  def within_price_range(min, max)
    @listings.select do |listing|
      listing.price >= min and listing.price < max
    end
  end

end
