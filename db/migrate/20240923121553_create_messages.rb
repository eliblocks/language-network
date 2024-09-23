class CreateMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :messages do |t|
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: "user"
      t.text :content, null: false

      t.timestamps
    end
  end
end
