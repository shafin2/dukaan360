class CreateAdminUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_users do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      t.timestamps
    end

    add_index :admin_users, :email,                unique: true
    add_index :admin_users, :reset_password_token, unique: true
  end
end
