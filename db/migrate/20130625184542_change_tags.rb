class AddColumnsToTags < ActiveRecord::Migration
  def change
    add_column :tags, :display, :string
    add_column :tags, :search_term, :string
    add_column :tags, :complexity, :integer
    remove_column :tags, :listing_id
    remove_column :tags, :name
  end
end
