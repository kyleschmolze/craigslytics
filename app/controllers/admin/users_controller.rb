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

  def new
    @user = User.new

    respond_to do |format|
      format.html { render layout: 'all' } # new.html.erb
      format.json { render json: @user }
    end
  end

  def edit
    @user = User.find(params[:id])
  end


end
