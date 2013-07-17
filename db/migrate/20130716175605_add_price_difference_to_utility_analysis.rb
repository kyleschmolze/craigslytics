class AddPriceDifferenceToUtilityAnalysis < ActiveRecord::Migration
  def change
    add_column :utility_analyses, :price_difference, :integer
  end
end
