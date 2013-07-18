class UsersController < ApplicationController
  #before_filter :authenticate_user!

  def request_demo
    new_user = User.new() 
    new_user.email = params["email"] if params["email"].present? 

    redirect_to root_path, notice: "Thanks for your interest, we'll will get back to you as soon as possible!"
  end


end
