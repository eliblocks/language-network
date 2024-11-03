class AddSummaryToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :summary, :text
  end
end
