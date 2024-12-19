class AddDiscordToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :discord_id, :string
    add_column :users, :discord_username, :string

    add_index :users, :discord_id, unique: true
    add_index :users, :discord_username, unique: true
  end
end
