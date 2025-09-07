class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.string :category
      t.decimal :buying_price, precision: 10, scale: 2, null: false
      t.decimal :selling_price, precision: 10, scale: 2, null: false
      t.integer :quantity, default: 0, null: false
      t.date :expiry_date
      t.text :description
      t.string :sku
      t.text :image_url
      t.references :shop, null: false, foreign_key: true
      t.bigint :created_by_id, null: false

      t.timestamps
    end

    add_foreign_key :products, :users, column: :created_by_id
    add_index :products, :name
    add_index :products, :category
    add_index :products, :expiry_date
    add_index :products, :created_by_id
    add_index :products, [:shop_id, :category]
  end
end
