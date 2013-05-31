class AddProcessedToAnalysis < ActiveRecord::Migration
  def change
    add_column :analyses, :processed, :boolean, :default => false
  end
end
