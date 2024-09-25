class AddSearchToUser < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :search, :text
  end
end
