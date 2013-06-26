class AddExpiredAtToListings < ActiveRecord::Migration
  def change
    add_column :listings, :expired_at, :datetime
  end
end
