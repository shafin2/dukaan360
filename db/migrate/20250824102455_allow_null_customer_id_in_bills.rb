class AllowNullCustomerIdInBills < ActiveRecord::Migration[8.0]
  def change
    change_column_null :bills, :customer_id, true
  end
end
