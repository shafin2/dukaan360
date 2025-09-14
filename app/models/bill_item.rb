class BillItem < ApplicationRecord
  belongs_to :bill
  belongs_to :product
  
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than: 0 }
  
  before_save :calculate_total_price
  after_create :update_product_stock
  after_update :update_product_stock, if: :saved_change_to_quantity?
  after_destroy :restore_product_stock
  
  # Ransackable attributes for ActiveAdmin search
  def self.ransackable_attributes(auth_object = nil)
    ["bill_id", "created_at", "id", "product_id", "quantity", "total_price", "unit_price", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["bill", "product"]
  end
  
  private
  
  def calculate_total_price
    self.total_price = quantity * unit_price if quantity && unit_price
  end
  
  def update_product_stock
    # Note: Stock management is now handled in the controllers
    # This method is kept for compatibility but doesn't update stock directly
    # Stock updates happen through shop_inventories in the controllers
  end
  
  def restore_product_stock
    # Note: Stock restoration is now handled in the controllers
    # This method is kept for compatibility but doesn't restore stock directly
    # Stock restoration would need to happen through shop_inventories
  end
end
