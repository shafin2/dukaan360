class CreateStockTransfers < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_transfers do |t|
      t.references :product, null: false, foreign_key: true
      t.references :from_shop, null: false, foreign_key: { to_table: :shops }
      t.references :to_shop, null: false, foreign_key: { to_table: :shops }
      t.references :initiated_by, null: false, foreign_key: { to_table: :users }
      t.references :approved_by, null: true, foreign_key: { to_table: :users }
      t.references :business, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.text :reason, null: false
      t.integer :status, null: false, default: 0
      t.datetime :approved_at
      t.datetime :completed_at
      t.datetime :cancelled_at
      t.text :cancellation_reason

      t.timestamps
    end
    
    # Performance indexes (foreign key indexes are auto-created)
    add_index :stock_transfers, :status
    add_index :stock_transfers, [:from_shop_id, :status]
    add_index :stock_transfers, [:to_shop_id, :status]
    add_index :stock_transfers, :created_at
  end
end
