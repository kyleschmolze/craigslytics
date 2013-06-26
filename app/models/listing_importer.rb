class ListingImporter < ActiveRecord::Base
  attr_accessible :api_key, :source, :user_id
end
