class AddFieldsToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :description, :text
    add_column :products, :sku, :string
  end
end
