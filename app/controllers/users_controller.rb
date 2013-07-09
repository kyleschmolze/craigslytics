class UsersController < ApplicationController
  before_filter :authenticate_user!

  def request_demo
    new_user = User.new() 
    new_user.email = params["email"] if params["email"].present? 
  end


end
