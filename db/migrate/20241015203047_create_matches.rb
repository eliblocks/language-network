class CreateMatches < ActiveRecord::Migration[7.2]
  def change
    create_table :matches do |t|
      t.references :searching_user, null: false, foreign_key: { to_table: "users" }
      t.references :matched_user, null: false, foreign_key: { to_table: "users" }
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :matches, [ :searching_user_id, :matched_user_id ], unique: true
  end
end
