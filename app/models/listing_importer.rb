require 'importers/zillow_importer'
require 'importers/craigslist_importer'

class ListingImporter < ActiveRecord::Base
  attr_accessible :api_key, :source, :user_id

  @queue = :importing

  def self.perform(listing_importer_id)
    listing_importer = ListingImporter.find listing_importer_id

    if listing_importer.source == 'zillow'
      zillow_importer = ZillowImporter.new
      zillow_importer.import(listing_importer)

    elsif listing_importer.source == 'craigslist'
      craigslist_importer = CraigslistImporter.new
      craigslist_importer.import(listing_importer)
    end
  end

end
