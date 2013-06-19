class AddUIdToListingsTable < ActiveRecord::Migration
  def change
    add_column :listings, :u_id, :string
  end
end
