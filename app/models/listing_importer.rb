require 'importers/zillow_importer'
require 'importers/craigslist_importer'
require 'importers/ygl_importer'

class ListingImporter < ActiveRecord::Base
  attr_accessible :api_key, :source, :user_id, :metro

  @queue = :importing

  def self.run_importer(listing_importer_id)
    listing_importer = ListingImporter.find listing_importer_id
    begin
       
      if listing_importer.source == 'zillow'
        zillow_importer = ZillowImporter.new
        zillow_importer.import(listing_importer)

      elsif listing_importer.source == 'craigslist'
        craigslist_importer = CraigslistImporter.new
        craigslist_importer.import(listing_importer)

      elsif listing_importer.source == 'ygl'
        ygl_importer = YglImporter.new
        ygl_importer.import(listing_importer)
      end

    rescue => e
      if Rails.env.production?
        sleep 60
        Resque.enqueue self, listing_importer_id 
      end
      raise
    end
  end

  def self.perform(func, arg1)
    self.send func, arg1
  end

  def self.enqueue(importer_id)
    if Rails.env.production?
      Resque.enqueue(ListingImporter, :run_importer, importer_id)
    else
      ListingImporter.run_importer importer_id
    end
  end

end
