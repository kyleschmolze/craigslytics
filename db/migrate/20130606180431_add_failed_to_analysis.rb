class AddFailedToAnalysis < ActiveRecord::Migration
  def change
    add_column :analyses, :failed, :boolean, default: false
  end
end
