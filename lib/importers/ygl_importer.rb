require 'importers/schemas/ygl_schema'
require 'open-uri'

class YglImporter
  attr_accessor :listing_importer, :use_feed_with_invalid_listing_for_test

  def import(importer)
    self.listing_importer = importer

    start = Time.now

    if self.num_pages > 1
      for page in 1..self.num_pages
        self.feed(:page => page).each do |listing|
          self.save_listing(listing)

          if Rails.env.development? and stats[:total] >= 100 #testing
            p stats
            return 
          end
        end
      end
      p stats
    end

    Listing.where(user_id: self.listing_importer.user_id).where("updated_at < ?", start).update_all(expired_at: 1.minute.ago)
  end

  def save_listing(listing)
    if stats[:total] % 100 == 0 and Rails.env.development?
      2.times {p "####################"}
      p "#{stats[:total]}"
      2.times {p "####################"}
    end



    detail = ListingDetail.where(source: 'ygl', u_id: listing.css("ID").text).first_or_initialize

    new = detail.new_record?
    if detail.update_attributes(
      raw_body: listing.to_s,
      body_type: 'XML',
      user_id: self.listing_importer.user_id
    )
      stats[:saved] += 1
      if !new
        stats[:errors]['changed attrs'] << "body #{detail.id}," if detail.body_changed?
        stats[:errors]['changed attrs'] << "body_type #{detail.id}," if detail.body_type_changed?
        stats[:errors]['changed attrs'] << "user_id #{detail.id}," if detail.user_id_changed?
      end
    else
      for e in detail.errors.full_messages
        stats[:errors][e] ||= 0
        stats[:errors][e] += 1
      end
    end

    stats[:total] += 1
  end

  def feed(options = {})
    page = options[:page] || 1
    YglSchema.parse(open(self.endpoint(page: page)), :lazy => true)

    result = Net::HTTP.get_response(URI.parse(self.endpoint(page: page)))
    page = Nokogiri::XML(result.body)
    page.css('Listing')
  end

  def endpoint(options = {})
    page = options[:page] || 1
    "http://www.yougotlistings.com/api/rentals/search.php?key=#{self.listing_importer.api_key}&detail_level=2&page_count=50&page_index=#{page}&min_rent=600"
  end

  def num_pages
    return @num_pages if @num_pages.present?

    result = Net::HTTP.get_response(URI.parse(self.endpoint))
    page = Nokogiri::XML(result.body)

    @num_pages = (page.css("Total").first.text.to_i / page.css("PageCount").first.text.to_i) 
    @num_pages = 1 if @numpages == 0

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
