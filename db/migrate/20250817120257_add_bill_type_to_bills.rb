class AddBillTypeToBills < ActiveRecord::Migration[8.0]
  def change
    add_column :bills, :bill_type, :string
  end
end
