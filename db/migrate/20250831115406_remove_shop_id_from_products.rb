class RemoveShopIdFromProducts < ActiveRecord::Migration[8.0]
  def up
    # First, ensure all products have business_id set
    # This migration assumes business_id has been added and populated
    
    # Remove the foreign key constraint first
    remove_foreign_key :products, :shops if foreign_key_exists?(:products, :shops)
    
    # Remove the index on shop_id
    remove_index :products, :shop_id if index_exists?(:products, :shop_id)
    
    # Remove the shop_id column
    remove_column :products, :shop_id
    
    # Remove the quantity column since inventory is now tracked in shop_inventories
    remove_column :products, :quantity if column_exists?(:products, :quantity)
  end
  
  def down
    # Add back the shop_id column and quantity
    add_reference :products, :shop, foreign_key: true
    add_column :products, :quantity, :integer, default: 0, null: false
    
    # Note: Data recovery would need to be handled separately
    # This is primarily for development use
  end
end
