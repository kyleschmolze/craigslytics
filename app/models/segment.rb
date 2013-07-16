class Segment
  attr_reader :listings, :median, :pictures, :average_pictures, :min_price, :max_price, :increment,
    :adjusted_min, :adjusted_max, :unique_id

  def initialize(listings, options={})
    @listings = listings.reorder(:price)
    @tags = options[:tags]
    if options[:comps].blank?
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
      bars = options[:bars] ||= 14
      while (@max_price - @min_price)/@increment > bars
        @increment += 50
      end
      @adjusted_min = @min_price - (@min_price % @increment)
      @adjusted_max = @max_price - (@max_price % @increment) + @increment
      @unique_id = SecureRandom.uuid
    else
      if !options[:interval].blank?
        @min_price = @listings.first.price ||= 0
        @max_price = @listings.last.price
        @increment = options[:interval] ||= 150
        @adjusted_min = @min_price - (@min_price % @increment)
        @adjusted_max = @max_price - (@max_price % @increment) + @increment
      else
        @unique_id = SecureRandom.uuid
      end
    end
  end

  def within_price_range(min, max)
    @listings.select do |listing|
      listing.price >= min and listing.price < max
    end
  end

  def average_with_util(tags, utility, listings)
    include_tag_list = tags + [utility]
    include_tag_list = include_tag_list.uniq
    exclude_tag_list = Tag.where(category: "utility").all - include_tag_list

    ids = []
    for tag in include_tag_list do
      ids << tag.listings.map{|l| l.id}
    end
    if ids.present?
      ids = ids.inject(:&)
    end

    for tag in exclude_tag_list do
      ids = ids - tag.listings.map{|l| l.id}
    end
    
    prices = listings.where(id: ids).map{|l| l.price} 
    len = prices.count
    if len > 0
      med = (prices[(len - 1) / 2] + prices[len / 2]) / 2 
    else
      med = nil
    end
    return med
  end

  def average_without_util(tags, utility, listings)
    include_tag_list = tags - [utility]
    exclude_tag_list = Tag.where(category: "utility").all - include_tag_list

    ids = []
    for tag in include_tag_list do
      ids << tag.listings.map{|l| l.id}
    end
    if ids.present?
      ids = ids.inject(:&)
    end

    for tag in exclude_tag_list do
      ids = ids - tag.listings.map{|l| l.id}
    end

    prices = listings.where(id: ids).map{|l| l.price} 
    len = prices.count
    if len > 0
      med = (prices[(len - 1) / 2] + prices[len / 2]) / 2 
    else
      med = nil
    end
    return med
  end

end
