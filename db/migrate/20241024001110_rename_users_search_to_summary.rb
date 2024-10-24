class RenameUsersSearchToSummary < ActiveRecord::Migration[7.2]
  def change
    rename_column :users, :search, :summary
  end
end
