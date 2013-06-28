class Segment
  attr_reader :listings, :median, :pictures, :average_pictures, :min_price, :max_price, :increment,
    :adjusted_min, :adjusted_max, :unique_id

  def initialize(listings)
    @listings = listings.reorder(:price)
    len = @listings.count
    if len > 0
      @median = (@listings[(len - 1) / 2].price + @listings[len / 2].price) / 2 
    else
      @median = nil
    end
    #@pictures = []
    #count = 0
    #for listing in @listings do 
      #if listing.pictures.present?
        #@pictures << listing.pictures.sample
        #count += listing.pictures.count 
      #end
    #end
    #@pictures = @pictures.uniq {|i| i.gsub(/https?:\/\//, '').gsub(/^.*\//, '') }
    #@average_pictures = count/len 
    @min_price = @listings.first.price ||= 0
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

  def average_with_util(utility)
    ids = []
    ids << Tag.where(search_term: utility).first.listings.map{|l| l.id}
    ids << self.listings.map{|l| l.id}
    ids = ids.inject(:&)
    prices = self.listings.where(id: ids).map{|l| l.price} 
    len = prices.count
    if len > 0
      med = (prices[(len - 1) / 2] + prices[len / 2]) / 2 
    else
      med = nil
    end
    return med
  end

  def average_without_util(utility)
    ids = []
    ids << Tag.where("search_term IS NOT ?", utility).first.listings.map{|l| l.id}
    ids << self.listings.map{|l| l.id}
    ids = ids.inject(:&)
    prices = self.listings.where(id: ids).map{|l| l.price} 
    len = prices.count
    if len > 0
      med = (prices[(len - 1) / 2] + prices[len / 2]) / 2 
    else
      med = nil
    end
    return med
  end

end
