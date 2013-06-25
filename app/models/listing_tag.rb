class ListingTag < ActiveRecord::Base
  attr_accessible :listing_id, :tag_id
  validate do |lt| 
    if ListingTag.where(listing_id:lt.listing_id, tag_id:lt.tag_id).exists?
      listing_tag.errors[:base] << "ListingTag associations are unique"
    end
  end
end
