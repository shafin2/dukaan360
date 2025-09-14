# Create migration file for business inventory
class CreateShops < ActiveRecord::Migration[8.0]
  def change
    create_table :shops do |t|
      t.string :name, null: false
      t.text :address
      t.jsonb :settings, default: {}

      t.timestamps
    end

    add_index :shops, :name
  end
end
