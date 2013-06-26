require 'importers/schemas/zillow_schema'
require 'open-uri'

class ZillowImporter
  attr_accessor :listing_importer, :use_feed_with_invalid_listing_for_test

  @queue = :importing

  def self.perform(listing_importer_id)
    #create instance
    zillow_importer = ZillowImporter.new
    zillow_importer.listing_importer = ListingImporter.find listing_importer_id

    #run!
    zillow_importer.import
  end

  def import

    start = Time.now

    if self.num_pages > 1
      for page in 1..self.num_pages
        self.feed(:page => page).each do |listing|
          self.save_listing(listing)
        end
      end
    end

    Listing.where(user_id: self.listing_importer.user_id).where("updated_at < ?", start).update_all(expired_at: 1.minute.ago)
    p stats
  end

  def save_listing(listing)
    if stats[:total] % 100 == 0 and Rails.env.development?
      2.times {p "####################"}
      p "#{stats[:total]}"
      2.times {p "####################"}
    end

    return if stats[:total] >= 100 #First runs

    detail = ListingDetail.new(
      raw_body: listing.to_s,
      body_type: 'xml',
      source: 'zillow',
      user_id: self.listing_importer.user_id
    )

    if detail.save
      stats[:saved] += 1
    else
      for e in detail.errors.full_messages
        stats[:errors][e] ||= 0
        stats[:errors][e] += 1
      end
    end

    stats[:total] += 1

    return

    #TODO merge into cenzo's listing.rb
    #already exists?
    if match = user.listings.where(:external_id => listings.external_id).first

      attrs = listings.attributes
      for i in ['id', 'created_at', 'updated_at', 'cluster_id']
        attrs.delete(i)
      end

      #TODO not sure about setting expired_at 1 day away, could be of variable length? Might not matter.

      match.touch #so that later, stats[:deactivated] can use where(updated_at < start)
      match.update_column(:expired_at, 1.day.from_now)

    end
  end

  def feed(options = {})
    page = options[:page] || 1
    ZillowSchema.parse(open(self.endpoint(page: page)), :lazy => true)

    result = Net::HTTP.get_response(URI.parse(self.endpoint(page: page)))
    page = Nokogiri::XML(result.body)
    page.css('listing')
  end

  def endpoint(options = {})
    page = options[:page] || 1
    "http://api.rentalapp.zillow.com/#{self.listing_importer.api_key}/listings.xml?limit=50&page=#{page}"
  end

  def num_pages
    return @num_pages if @num_pages.present?

    result = Net::HTTP.get_response(URI.parse(self.endpoint))
    page = Nokogiri::XML(result.body)

    num_listings = page.css("total_count").text.to_i
    @num_pages = ((num_listings - 1) / 50) + 1

    @num_pages
  end

  def stats
    return @stats if @stats.present?
    @stats = {
      :saved => 0,
      :deleted => 0,
      :touched => 0,
      :total => 0,
      :deactivated => 0,
      :errors => {
        :too_far => 0, 
        :no_students => 0, 
        :too_cheap => 0
      }
    }
    @stats
  end
end
