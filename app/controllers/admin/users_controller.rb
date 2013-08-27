class Admin::UsersController < ApplicationController
  before_filter :authenticate_user!
  before_filter do 
    redirect_to(root_path, notice: "You must be an admin to access that page!") unless current_user.try(:admin?)
  end

  def dashboard
    @user_inquiries = UserInquiry.all
    @users = User.where(admin: false).all
    render layout: 'all' 
  end

  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        format.html { redirect_to dashboard_admin_users_path, notice: 'User was successfully created.' }
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: "new", layout: "all"}
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def run_listings_importer
    @user = User.find(params[:id])
    @importer = ListingImporter.where(user_id: @user.id).first
    ListingImporter.enqueue @importer.id
    redirect_to dashboard_admin_users_path, notice: "Enqueued listings importer for #{@user.email}. To monitor activity, go to rentalyzer.com/resque" 
  end

  def run_utility_analyses
    @user = User.find(params[:id])
    Listing.enqueue @user.id
    redirect_to dashboard_admin_users_path, notice: "Enqueued utility analyses for #{@user.email}. To monitor activity, go to rentalyzer.com/resque" 
  end

  def new
    @user = User.new

    respond_to do |format|
      format.html { render layout: 'all' } # new.html.erb
      format.json { render json: @user }
    end
  end

  def update
    @user = User.find(params[:id])

    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to dashboard_admin_users_path, notice: 'User was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit", layout: "all" }
        format.json { render json: @listing_importer.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @user = User.find(params[:id])
    render layout: 'all' 
  end

end
