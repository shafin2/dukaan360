class AllowNullCreatedByIdInProducts < ActiveRecord::Migration[8.0]
  def change
    change_column_null :products, :created_by_id, true
  end
end
