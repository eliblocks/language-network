class AddTelegramUsernameToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :telegram_username, :string
  end
end
