class AddAveragePriceToAnalyses < ActiveRecord::Migration
  def change
    add_column :analyses, :average_price, :integer
  end
end
