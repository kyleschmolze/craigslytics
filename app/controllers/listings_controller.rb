class ListingsController < ApplicationController
  # GET /listings
  # GET /listings.json
  def index
    if params[:tags].present?
      tags = params[:tags].split(',').map(&:strip).map(&:titleize)
      tables = []
      for tag in tags do
        tables << Tag.where(name: tag).pluck(:listing_id)
      end
      ids = tables.inject(:&)
      @listings = Listing.where("id IN (?)", ids).order(:price).includes(:tags).page(params[:page]).per(50)
    elsif params[:analysis_id].present?

      @analysis = Analysis.find(params[:analysis_id])
      tags = "#{@analysis.tags}".split(',').map(&:strip).map(&:titleize)
      tables = []
      for tag in tags do
        tables << Tag.where(name: tag).pluck(:listing_id)
      end
      ids = tables.inject(:&)
      @listings = @analysis.listings.where("id IN (?)", ids).order(:u_id).includes(:tags).page(params[:page]).per(50)

      all_listings = @analysis.listings.where("id IN (?)", ids).order(:u_id).includes(:tags)
      @overview = @analysis.get_segment_with_listings(all_listings) if all_listings.length > 0
    else
      @listings = Listing.order(:price).includes(:tags).page(params[:page]).per(50)
    end

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
