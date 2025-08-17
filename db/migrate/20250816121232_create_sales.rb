class CreateSales < ActiveRecord::Migration[8.0]
  def change
    create_table :sales do |t|
      t.references :product, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      t.datetime :sale_date, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps
    end

    add_index :sales, :sale_date
    add_index :sales, [:product_id, :sale_date]
    add_index :sales, [:user_id, :sale_date]
  end
end
