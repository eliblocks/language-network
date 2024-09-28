class AddTelegramIdToUser < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :telegram_id, :string
  end
end
