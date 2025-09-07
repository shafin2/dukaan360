class UpdateUsersForBusinessStructure < ActiveRecord::Migration[8.0]
  def change
    # Add business reference to users
    add_reference :users, :business, null: true, foreign_key: true
    
    # Make shop_id optional since business admins don't need a specific shop
    change_column_null :users, :shop_id, true
  end
end
