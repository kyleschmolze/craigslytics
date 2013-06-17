class AddRadiusToAnalysis < ActiveRecord::Migration
  def change
    add_column :analyses, :radius, :integer
  end
end
