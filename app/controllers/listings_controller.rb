class ListingsController < ApplicationController
  # GET /listings
  # GET /listings.json
  def index
    @listings = Listing
    # If bedrooms is set, 
      # only grab listings with that number of bedrooms
    if params[:bedrooms].present? and !params[:bedrooms][0].blank?
      bedrooms = params[:bedrooms][0]
      @listings = @listings.where(:bedrooms => bedrooms)
    end
    # If address is set,
      # only grab listings within a mile of that address
    if params[:address].present? and !params[:address][0].blank?
      address = params[:address][0]
      @listings = @listings.near(address, 1)
    end
    @listings = @listings.where("price IS NOT ?", nil)
    # Building hash of utility medians
    @utilities = {}
    for utility in Tag.where(category: "utility") do 
      # If there are tags in the parameters,
        # build a list of the tags in the parameters with and without the current utility
      if params[:tags].present?
        list_without_current_util = params[:tags].keys - ["#{utility.search_term}"]
        list_with_current_util = (params[:tags].keys + ["#{utility.search_term}"]).uniq
      # Else there are no tags in the parameters,
        # build a list with just the current tag and with no tags (nil)
      else
        list_without_current_util = nil
        list_with_current_util = ["#{utility.search_term}"]
      end

      # Determine median of the listings without the current utility
      # If list of tags without current utility is not nil,
        # grab all listing prices that have the tags in the list of tags
      if list_without_current_util.present?
        tables = []
        for tag in list_without_current_util
          tables << Tag.where(search_term: tag).first.listings.map{|l| l.id}
        end
        ids = tables.inject(:&)
        prices = @listings.where(id: ids).reorder(:price).map{|l| l.price} 
      # Else the list of tags is empty,
        # grab all listing prices
      else
        prices = @listings.reorder(:price).all.map{|l| l.price}
      end
      len = prices.count
      if len > 0
        med = "$#{(prices[(len - 1) / 2] + prices[len / 2]) / 2}"
      else
        med = "N/A"
      end
      @utilities["without_#{utility.search_term}"] = med

      # Determine median of the listings with the current utility
      tables = []
      for tag in list_with_current_util
        tables << Tag.where(search_term: tag).first.listings.map{|l| l.id}
      end
      ids = tables.inject(:&)
      prices = @listings.where(id: ids).reorder(:price).map{|l| l.price} 
      len = prices.count
      if len > 0
        med = "$#{(prices[(len - 1) / 2] + prices[len / 2]) / 2}"
      else
        med = "N/A"
      end
      @utilities["with_#{utility.search_term}"] = med
    end
    # If tags are set, 
      # only grab listings that contain all the tags (intersection of all selected tags)
    if params[:tags].present?
      tags = params[:tags].keys
      tables = []
      for tag in tags do
        tables << Tag.where(search_term: tag).first.listings.map{|l| l.id}
      end
      ids = tables.inject(:&)
      @listings = @listings.where(:id => ids) 
    end
    # Order the listings by price, pull tags, and paginate
    @segment = Segment.new(@listings) if @listings.present?
    @listings = @listings.order(:price).includes(:tags).page(params[:page]).per(50)


    respond_to do |format|
      format.html { render layout: 'default' }
      format.json { render json: @listings }
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
