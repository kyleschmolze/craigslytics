class ListingTag < ActiveRecord::Base
  attr_accessible :listing_id, :tag_id
  belongs_to :tag
  belongs_to :listing

  validate do |lt| 
    if ListingTag.where(listing_id: lt.listing_id, tag_id: lt.tag_id).exists?
      lt.errors[:base] << "ListingTag associations are unique"
    end

    # A listing can only have one unit_type
    if lt.new_record? 
      if Tag.find(lt.tag_id).category == "unit_type"
        found = false
        ListingTag.where(listing_id: lt.listing_id).each do |i|
          found = true if i.tag.category == "unit_type" if i.tag
        end
        lt.errors[:tag] << "Listings can only have one unit_type" if found
      end
    end
  end
end
