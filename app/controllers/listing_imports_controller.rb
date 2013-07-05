class ListingImportsController < ApplicationController
  # GET /listing_imports
  # GET /listing_imports.json
  def index
    @listing_imports = ListingImport.order('created_at DESC')

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @listing_imports }
    end
  end

  # GET /listing_imports/1
  # GET /listing_imports/1.json
  def show
    @listing_import = ListingImport.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json do
        if @listing_import.completed_at
          render json: { done: 1, listing_import: @listing_import }
        else
          render json: { success: 1, listing_import: @listing_import }
        end
      end
    end
  end

  # GET /listing_imports/new
  # GET /listing_imports/new.json
  def new
    @listing_import = ListingImport.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @listing_import }
    end
  end

  # GET /listing_imports/1/edit
  def edit
    @listing_import = ListingImport.find(params[:id])
  end

  # POST /listing_imports
  # POST /listing_imports.json
  def create
    @listing_import = ListingImport.new(params[:listing_import])

    respond_to do |format|
      if @listing_import.save
        format.html { redirect_to @listing_import, notice: 'Listing import was successfully created.' }
        format.json { render json: @listing_import, status: :created, location: @listing_import }
      else
        format.html { render action: "new" }
        format.json { render json: @listing_import.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /listing_imports/1
  # PUT /listing_imports/1.json
  def update
    @listing_import = ListingImport.find(params[:id])

    respond_to do |format|
      if @listing_import.update_attributes(params[:listing_import])
        format.html { redirect_to @listing_import, notice: 'Listing import was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @listing_import.errors, status: :unprocessable_entity }
      end
    end
  end

  def poll
    if Rails.env.production?
      Resque.enqueue ListingImporter, (ListingImporter.where(:source => 'craigslist').first.id)
    end
    respond_to do |format|
      format.html { redirect_to listing_imports_path, notice: 'Polling Job Enqueued.' }
      format.json { head :no_content }
    end
  end

  # DELETE /listing_imports/1
  # DELETE /listing_imports/1.json
  def destroy
    @listing_import = ListingImport.find(params[:id])
    @listing_import.destroy

    respond_to do |format|
      format.html { redirect_to listing_imports_url }
      format.json { head :no_content }
    end
  end
end
