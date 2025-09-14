class AddBusinessInventoryToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :business_inventory_quantity, :integer, default: 0, null: false
    add_index :products, :business_inventory_quantity
  end
end 