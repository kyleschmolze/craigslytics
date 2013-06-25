class Tag < ActiveRecord::Base
  attr_accessible :listing_id, :name
  belongs_to :listing
  has_many :listing_tags 
  has_many :listings, through: :listing_tags

  NAMES = [
    "Garden",
    "Patio",
    "Fireplace",
    "Stove",
    "Hardwood",
    "View",
    "High Ceilings",
    "Carpeted",
    "Tile Floors",
    "Granite Counter",
    "Marble Counter",
    "Recently Remodeled",
    "Dishwasher",
    "Microwave",
    "Balcony",
    "Garbage Disposal",
    "Tub"
  ]

  # name[matcher]
  # all 'simple' utilities need only look for 'includ' within 30 chars
  UTILITIES = {
    water: "water",  # confirmed simple
    electricity: "electric",  # confirmed simple
    heat: "heat",              # confirmed simple
    cable: "cable",   # confirmed simple
    internet: "internet",  # confirmed simple
    gas: "gas",  # complex
  }


=begin
  TYPES
    house: "single family"
    condo: "condo"
    apartment_building: "complex", or "building"
    apartment: 
=end

  def detect_in_listing(l)
    if self.body.present?
      if self.complexity == 1
        detect_simple l 
      else if self.complexity == 2
        detect_utility l 
      else 
        detect complex l
      end
    end
  end

  def detect_simple(l)
    range = 40
    m1 = (self.body.match /\binclud.{0,#{range}}\b#{matcher}\b/i)
    m2 = (self.body.match /\b#{matcher}\b.{0,#{range}}\binclud/i)
    if m1 or m2 
      l.tags.build({display:'self.display', search_term: 'self.search_term', complexity: 'self.complexity'}) 
    end
  end

      if gas 
        matcher = "gas"
        if self.body.present?
          if (self.body =~ /includ/i)
            m1 = (self.body.match /\binclud.{0,#{range}}\b#{matcher}\b............................................................../i)
              m2 = (self.body.match /..............................................................\b#{matcher}\b.{0,#{range}}\binclud/i)
              # if !m1.match /\bgas.{0,3}range/
              # if !m1.match /\bgas.{0,3}stove/
              # if !m1.match /\bgas.{0,3}fireplace/
              # if !m1.match /pay.{0,30}gas/
          end
        end
      end

      if internet 
        min_dist = 20
        max_dist = 50
        matcher = "wi-fi" # 'internet', 'wifi', 'wi-fi' 
        if self.body.present?
          if (self.body =~ /includ/i)
            m1 = (self.body.match /\binclud.{0,#{max_dist}}\b#{matcher}\b............................................................../i)
              m2 = (self.body.match /..............................................................\b#{matcher}\b.{0,#{max_dist}}\binclud/i)
              puts m1[0] if m1
            puts m2[0] if m2
          end
        end
      end


      #  if furnished,
      min_dist = 20
      max_dist = 50
      matcher = "furnished" 
      if self.body.present?
        m1 = (self.body.match /.........................................\b#{matcher}......................................................./i)
        puts m1[0] if m1
      end

      # if furnished, else if partially furnished

      # if partially furnished 
      min_dist = 20
      max_dist = 50
      matcher = "partially furnished" 
      if self.body.present?
        m2 = (self.body.match /..........................#{matcher}..................................../i)
          puts m2[0] if m2
      end
    end



  end
end
