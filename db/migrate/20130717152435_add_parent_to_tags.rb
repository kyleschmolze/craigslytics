class AddParentToTags < ActiveRecord::Migration
  def change
    add_column :tags, :parent, :string
  end
end
