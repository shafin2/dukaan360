class CreateShopInventories < ActiveRecord::Migration[8.0]
  def change
    create_table :shop_inventories do |t|
      t.references :shop, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :business, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 0
      t.integer :min_stock_level, null: false, default: 10
      t.integer :max_stock_level, null: false, default: 100
      t.integer :reorder_point, null: false, default: 20
      t.datetime :last_restocked_at
      t.text :restock_notes

      t.timestamps
    end
    
    # Ensure unique product per shop (no duplicate inventory records)
    add_index :shop_inventories, [:shop_id, :product_id], unique: true, name: 'index_shop_inventories_unique_shop_product'
    
    # Performance indexes (business_id index is auto-created by foreign key)
    add_index :shop_inventories, :quantity
    add_index :shop_inventories, [:quantity, :reorder_point], name: 'index_shop_inventories_stock_levels'
  end
end
