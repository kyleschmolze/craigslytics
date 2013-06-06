class ListingComparison < ActiveRecord::Base
  attr_accessible :listing_1_id, :listing_2_id, :score, :duplicate, :address_score, :bedrooms_score, :location_score, :price_score

  belongs_to :listing_1, :class_name => "Listing"
  belongs_to :listing_2, :class_name => "Listing"


  validates_presence_of :listing_1_id, :listing_2_id, :score

  validate do |listing_comparison|
    if listing_comparison.new_record? 
      if ListingComparison.where(listing_1_id:listing_comparison.listing_1_id, 
                                 listing_2_id:listing_comparison.listing_2_id).exists? or
        ListingComparison.where(listing_1_id:listing_comparison.listing_2_id, 
                                listing_2_id:listing_comparison.listing_1_id).exists? 
        listing_comparison.errors[:base] << "Listing Comparison already exists on these two listings"
      end
      if listing_comparison.listing_1_id == listing_comparison.listing_2_id
        listing_comparison.errors[:base] << "Cannot create Listing Comparison with identical listing ids"
      end
    end
  end


  # nested for loop grabs comparisons containing any two listings from the array of duplicates
  # marks each comparison as duplicate 
  def self.mark_from_listings(ls) 
    cs = Array.new
    for outer in ls
      for inner in ls
        res = ListingComparison.where("listing_1_id == ? AND listing_2_id == ?", outer, inner).first
        if res.present? 
          cs.push res
        end
      end
    end
    for c in cs
      p 1
      c.duplicate = 1
    end
  end

end

