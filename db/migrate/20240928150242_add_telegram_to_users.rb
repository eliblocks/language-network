class AddTelegramToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :telegram_id, :string
    add_column :users, :telegram_username, :string

    add_index :users, :telegram_id, unique: true
    add_index :users, :telegram_username, unique: true
  end
end
