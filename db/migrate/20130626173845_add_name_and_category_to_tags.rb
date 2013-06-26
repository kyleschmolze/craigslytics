class AddNameAndCategoryToTags < ActiveRecord::Migration
  def change
    add_column :tags, :name, :string
    add_column :tags, :category, :string
  end
end
