class ListingImport < ActiveRecord::Base
  attr_accessible :completed_at, :current_anchor, :current_date, :failed_listings, :new_listings, :updated_listings, :listing_importer_id
end
