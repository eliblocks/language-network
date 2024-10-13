class AddStatusToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :status, :string, null: false, default: "initial"
  end
end
