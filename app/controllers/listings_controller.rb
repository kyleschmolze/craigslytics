class ListingsController < ApplicationController
  before_filter :authenticate_user!
  # GET /listings
  # GET /listings.json
  def index
    @listings = Listing
    @geocoded_address = nil
    # If bedrooms is set, 
    #   only grab listings with that number of bedrooms
    if params[:bedrooms].present? and !params[:bedrooms].blank?
      bedrooms = params[:bedrooms]
      @listings = @listings.where(:bedrooms => bedrooms)
    end
    # If address is set,
    #   only grab listings within a mile of that address
    if params[:address].present? and !params[:address].blank?
      address = params[:address]
      @geocoded_address = Geocoder.search(address)[0]
      if @geocoded_address.present?
        @listings = @listings.near([@geocoded_address.geometry["location"]["lat"], @geocoded_address.geometry["location"]["lng"]], 1) 
      else
        @listings = @listings.near(nil, 1)
      end
    end
    # Building hash of utility medians
    @utilities = {}
    for utility in Tag.where(category: "utility") do 
      # Build tag lists:

      # If there are tags in the parameters,
      #   build a list of the tags in the parameters with the current utility
      #   and a list of the lasgs in the parameters without the current utility
      if params[:tags].present?
        list_without_current_util = params[:tags].keys - ["#{utility.name}"]
        list_with_current_util = (params[:tags].keys + ["#{utility.name}"]).uniq
      # Else there are no tags in the parameters,
      #   build a list with just the current tag and a list with no tags (nil)
      else
        list_without_current_util = nil
        list_with_current_util = ["#{utility.name}"]
      end
      # Determine median of the listings without the current utility:
      
      # If list of tags without current utility is not nil,
      #   grab all listing prices that have the tags in the list of tags 
      #   AND don't have the current utility
      if list_without_current_util.present?
        tables = []
        for tag in list_without_current_util
          tables << Tag.where(name: tag).first.listings.map{|l| l.id}
        end
        ids = tables.inject(:&)
        exclude_util_ids = Tag.where(name: utility.name).first.listings.map{|l| l.id}
        ids = ids - exclude_util_ids
        prices = @listings.where(id: ids).reorder(:price).map{|l| l.price} 
      # Else the list of tags is empty,
      #   grab all listing prices that don't have the current utility
      else
        ids = @listings.all.map{|l| l.id}
        exclude_util_ids = Tag.where(name: utility.name).first.listings.map{|l| l.id}
        ids = ids - exclude_util_ids
        prices = @listings.where(id: ids).reorder(:price).all.map{|l| l.price}
      end
      len = prices.count
      if len > 0
        med = (prices[(len - 1) / 2] + prices[len / 2]) / 2
      else
        med = nil
      end
      @utilities["without_#{utility.name}"] = med
      # Determine median of the listings with the current utility:

      tables = []
      for tag in list_with_current_util
        tables << Tag.where(name: tag).first.listings.map{|l| l.id}
      end
      ids = tables.inject(:&)
      prices = @listings.where(id: ids).reorder(:price).map{|l| l.price} 
      len = prices.count
      if len > 0
        med = (prices[(len - 1) / 2] + prices[len / 2]) / 2
      else
        med = nil
      end
      @utilities["with_#{utility.name}"] = med

      without = "without_#{utility.name}"
      with = "with_#{utility.name}"
      if @utilities[without] == nil or @utilities[with] == nil
        @utilities["value_#{utility.name}?"] = nil
      elsif @utilities[without] == @utilities[with]
        @utilities["value_#{utility.name}?"] = "equal"
        @utilities["percent_value_#{utility.name}"] = 0
      elsif @utilities[without] < @utilities[with]
        @utilities["value_#{utility.name}?"] = "increased"
        @utilities["percent_value_#{utility.name}"] = (( (@utilities[with] - @utilities[without]) / ( 1.0 * (@utilities[without]) )) * 100).round(2)
      else
        @utilities["value_#{utility.name}?"] = "decreased"
        @utilities["percent_value_#{utility.name}"] = (( (@utilities[with] - @utilities[without]) / ( 1.0 * (@utilities[without]) )) * -100).round(2)
      end

    end
    # If tags are set, 
    #   only grab listings that contain all the tags (intersection of all selected tags)
    if params[:tags].present?
      tags = params[:tags].keys
      tables = []
      for tag in tags do
        tables << Tag.where(name: tag).first.listings.map{|l| l.id}
      end
      ids = tables.inject(:&)
      @listings = @listings.where(:id => ids) 
    end
    @segment = Segment.new(@listings) if @listings.present?
    # Order the listings by price (will be ordered by [location & price] if address is set), pull tags, and paginate
    @listings = @listings.order(:price).includes(:tags).page(params[:page]).per(50)

    respond_to do |format|
      format.html { render layout: 'two_column' }
      format.json { render json: @listings }
      format.pdf { 
        render pdf: "listing_analysis_at_#{@geocoded_address.formatted_address}",
               layout: 'default',
               disposition: 'attachment',
               margin: { :bottom => 15 },
               footer: {
                 html: {
                   template: 'pdf_footer.pdf.erb'
                 },
               },
               show_as_html: params[:debug].present?
      }
    end
  end

  # GET /listings/utilities
  # GET /listings/utilities
  def utilities
    # Demo Account Sees All
    if current_user.admin?
      @listings = Listing.joins(:utility_analyses).where("price_difference > ?", 50).order("price_difference DESC").page(params[:page]).per(25)
    else 
      @listings = Listing.where(user_id: current_user.id).joins(:utility_analyses).where("price_difference > ?", 50).order("price_difference DESC").page(params[:page]).per(25)
    end
    respond_to do |format|
      format.html { render layout: 'all' }
      format.json { render json: @listings }
    end
  end

  # GET /listings/utility/:id
  # GET /listings/utility/:id.json
  def utility
    @listing = Listing.find(params[:id])

    respond_to do |format|
      format.html { render layout: 'all' }
      format.json { render json: @listing }
    end
  end

  def overview
    @listings = Listing
    @geocoded_address = nil
    # If bedrooms is set, 
    #   only grab listings with that number of bedrooms
    if params[:bedrooms].present? and !params[:bedrooms].blank?
      bedrooms = params[:bedrooms]
      @listings = @listings.where(:bedrooms => bedrooms)
    end
    # If address is set,
    #   only grab listings within a mile of that address
    if params[:address].present? and !params[:address].blank?
      address = params[:address]
      @geocoded_address = Geocoder.search(address)[0] 
      if @geocoded_address.present?
        @listings = @listings.near([@geocoded_address.geometry["location"]["lat"], @geocoded_address.geometry["location"]["lng"]], 1) 
      else
        @listings = @listings.near(nil, 1)
      end
    end

    # If tags are set, 
    #   only grab listings that contain all the tags (intersection of all selected tags)
    if params[:tags].present?
      tags = params[:tags].keys
      tables = []
      for tag in tags do
        tables << Tag.where(name: tag).first.listings.map{|l| l.id}
      end
      ids = tables.inject(:&)
      @listings = @listings.where(:id => ids) 
    end
    @segment = Segment.new(@listings) if @listings.present?
    # Order the listings by price (will be ordered by [location & price] if address is set), pull tags, and paginate
    @total = @listings
    @listings = @listings.order(:price).includes(:tags, :listing_detail).page(params[:page]).per(50)


    respond_to do |format|
      format.html { render layout: 'all' }
      format.json { render json: @listings }
      format.pdf { 
        render pdf: "listing_analysis_at_#{@geocoded_address.formatted_address}",
               layout: 'default',
               disposition: 'attachment',
               margin: { :bottom => 15 },
               footer: {
                 html: {
                   template: 'pdf_footer.pdf.erb'
                 },
               },
               show_as_html: params[:debug].present?
      }
    end
  end

  # GET /listings/:id
  # GET /listings/:id.json
  def show
    @listing = Listing.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @listing }
    end
  end

  # GET /listings/new
  # GET /listings/new.json
  def new
    @listing = Listing.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @listing }
    end
  end

  # GET /listings/1/edit
  def edit
    @listing = Listing.find(params[:id])
  end

  # POST /listings
  # POST /listings.json
  def create
    @listing = Listing.new(params[:listing])

    respond_to do |format|
      if @listing.save
        format.html { redirect_to @listing, notice: 'Analysis was successful.' }
        format.json { render json: @listing, status: :created, location: @listing }
      else
        format.html { render action: "new" }
        format.json { render json: @listing.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /listings/1
  # PUT /listings/1.json
  def update
    @listing = Listing.find(params[:id])

    respond_to do |format|
      if @listing.update_attributes(params[:listing])
        format.html { redirect_to @listing, notice: 'Listing was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @listing.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /listings/1
  # DELETE /listings/1.json
  def destroy
    @listing = Listing.find(params[:id])
    @listing.destroy

    respond_to do |format|
      format.html { redirect_to listings_url }
      format.json { head :no_content }
    end
  end
end
