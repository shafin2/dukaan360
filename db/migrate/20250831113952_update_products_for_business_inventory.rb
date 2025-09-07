class UpdateProductsForBusinessInventory < ActiveRecord::Migration[8.0]
  def change
    # Add business relationship to products
    add_reference :products, :business, null: false, foreign_key: true, default: 1
    
    # Add default stock level fields to products (can be overridden at shop level)
    add_column :products, :min_stock_level, :integer, default: 10
    add_column :products, :max_stock_level, :integer, default: 100
    add_column :products, :reorder_point, :integer, default: 20
    add_column :products, :unit, :string, default: 'piece', null: false
    
    # Remove shop_id from products (products now belong to business, not specific shop)
    # Note: This will be handled in a separate step after data migration
    
    # Add indexes for performance (business_id index is auto-created by foreign key)
    add_index :products, [:business_id, :category]
    # expiry_date index already exists from earlier migrations
  end
end
