class AddTelegramIndexesToUsers < ActiveRecord::Migration[7.2]
  def change
    add_index :users, :telegram_id, unique: true
    add_index :users, :telegram_username, unique: true
  end
end
