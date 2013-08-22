class CreateUserInquiries < ActiveRecord::Migration
  def change
    create_table :user_inquiries do |t|
      t.string :email

      t.timestamps
    end
  end
end
