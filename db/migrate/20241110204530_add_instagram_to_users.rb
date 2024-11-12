class AddInstagramToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :instagram_id, :string
    add_column :users, :instagram_username, :string

    add_index :users, :instagram_id, unique: true
    add_index :users, :instagram_username, unique: true
  end
end
