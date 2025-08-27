class AddBillToSales < ActiveRecord::Migration[8.0]
  def change
    add_reference :sales, :bill, null: true, foreign_key: true
  end
end
