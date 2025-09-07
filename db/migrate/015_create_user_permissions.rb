class CreateUserPermissions < ActiveRecord::Migration[8.0]
  def change
    create_table :user_permissions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :permission, null: false, foreign_key: true
      t.references :shop, null: true, foreign_key: true
      t.boolean :granted, default: true
      t.text :notes

      t.timestamps
    end

    add_index :user_permissions, [:user_id, :permission_id, :shop_id], unique: true, name: 'index_user_permissions_unique'
    add_index :user_permissions, :granted
  end
end
