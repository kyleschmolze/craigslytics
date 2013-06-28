class ListingsController < ApplicationController
  # GET /listings
  # GET /listings.json
  def index
    @listings = Listing
    # If tags are set, 
      # only grab listings that contain all the tags (intersection of all selected tags)
    if params[:tags].present?
      tags = params[:tags].keys
      tables = []
      for tag in tags do
        tables << Tag.where(search_term: tag).first.listings.map{|l| l.id}
      end
      ids = tables.inject(:&)
      puts "tags: #{tags}"
      @listings = @listings.where(:id => ids) 
    end
    # If bedrooms is set, 
      # only grab listings with that number of bedrooms
    if params[:bedrooms].present? and !params[:bedrooms][0].blank?
      bedrooms = params[:bedrooms][0]
      puts "bedrooms: #{bedrooms}"
      @listings = @listings.where(:bedrooms => bedrooms)
    end
    # If address is set,
      # only grab listings within a mile of that address
    if params[:address].present? and !params[:address][0].blank?
      address = params[:address][0]
      puts "address: #{address}"
      @listings = @listings.near(address, 1)
    end
    # Order the listings by price, pull tags, and paginate
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
