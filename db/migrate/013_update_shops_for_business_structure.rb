class UpdateShopsForBusinessStructure < ActiveRecord::Migration[8.0]
  def change
    # Add business reference to shops
    add_reference :shops, :business, null: false, foreign_key: true
    
    # Remove unique constraint on shop name since different businesses can have same shop names
    remove_index :shops, :name
    add_index :shops, [:business_id, :name], unique: true
  end
end
