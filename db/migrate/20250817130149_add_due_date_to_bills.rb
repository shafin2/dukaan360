class AddDueDateToBills < ActiveRecord::Migration[8.0]
  def change
    add_column :bills, :due_date, :date
  end
end
