class UserInquiry < ActiveRecord::Base
  attr_accessible :email

  validates_presence_of :email

  validate do |user_inquiry|
    user_inquiry.errors.add(:email, "is invalid") if user_inquiry.email.present? and user_inquiry.email.match(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i) == nil
  end
end
