class UserInquiriesController < ApplicationController
  def request_demo
    @new_user_inquiry = UserInquiry.new(params[:user_inquiry]) 
    if @new_user_inquiry.save
      redirect_to root_path, notice: "Thanks for your interest, we'll will get back to you as soon as possible!"
    else
      redirect_to root_path, notice: @new_user_inquiry.errors.full_messages.join(". ")
    end
  end
end
