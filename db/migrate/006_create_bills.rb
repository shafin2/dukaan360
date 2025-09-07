class CreateBills < ActiveRecord::Migration[8.0]
  def change
    create_table :bills do |t|
      t.references :customer, null: true, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :shop, null: false, foreign_key: true
      t.string :bill_number
      t.decimal :total_amount
      t.string :status
      t.datetime :bill_date
      t.text :notes
      t.string :bill_type
      t.date :due_date

      t.timestamps
    end
  end
end
