class AddTagsToAnalyses < ActiveRecord::Migration
  def change
    add_column :analyses, :tags, :string
  end
end
