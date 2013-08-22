class Admin::ListingImportersController < ApplicationController
  before_filter :authenticate_user!
  before_filter do 
    redirect_to(root_path, notice: "You must be an admin to access that page!") unless current_user.try(:admin?)
  end

  def create
    @listing_importer = ListingImporter.new(params[:listing_importer])

    respond_to do |format|
      if @listing_importer.save
        format.html { redirect_to dashboard_admin_users_path, notice: 'Listing importer was successfully created.' }
        format.json { render json: @listing_importer, status: :created, location: @listing_importer }
      else
        format.html { render action: "new", layout: "all"}
        format.json { render json: @listing_importer.errors, status: :unprocessable_entity }
      end
    end
  end

  def new
    @listing_importer = ListingImporter.new(params[:listing_importer])

    respond_to do |format|
      format.html { render layout: 'all' } # new.html.erb
      format.json { render json: @listing_importer }
    end
  end

  def edit
    @listing_importer = ListingImporter.find(params[:id])
  end

  def update
    @listing_importer = ListingImporter.find(params[:id])

    respond_to do |format|
      if @listing_importer.update_attributes(params[:listing_importer])
        format.html { redirect_to dashboard_admin_users_path, notice: 'Listing importer was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit", layout: "all" }
        format.json { render json: @listing_importer.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @listing_importer = ListingImporter.find(params[:id])
    @listing_importer.destroy

    respond_to do |format|
      format.html { redirect_to dashboard_admin_users_path }
      format.json { head :no_content }
    end
  end

end
