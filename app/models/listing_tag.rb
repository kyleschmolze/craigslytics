class ListingTag < ActiveRecord::Base
  attr_accessible :listing_id, :tag_id
  belongs_to :tag
  belongs_to :listing

  validate do |lt| 
    if ListingTag.where(listing_id: lt.listing_id, tag_id: lt.tag_id).exists?
      lt.errors[:base] << "ListingTag associations are unique"
    end

    # listings can only have one unit_type tag of each complexity
    # if we encounter a tag of same complexity, we delete it and replace with most recent
    # keeps tree structure, avoids things like house > condo
    if lt.new_record? 
      if Tag.find(lt.tag_id).category == "unit_type"
        found = false
        ListingTag.where(listing_id: lt.listing_id).each do |i|
          if i.tag
            if (i.tag.category == "unit_type" and i.tag.complexity == lt.tag.complexity)    
              i.delete
            end
          end
        end
      end
    end
  end
end
