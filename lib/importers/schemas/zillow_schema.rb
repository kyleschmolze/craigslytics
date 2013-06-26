class ZillowSchema
  include SAXMachine
  elements :listing, :as => :listings, :lazy => true
end
