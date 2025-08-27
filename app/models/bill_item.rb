class BillItem < ApplicationRecord
  belongs_to :bill
  belongs_to :product
  
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than: 0 }
  validates :total_price, numericality: { greater_than: 0 }, allow_nil: true
  
  before_validation :calculate_total_price
  after_save :update_product_stock, :update_bill_total
  after_destroy :restore_product_stock, :update_bill_total
  
  private
  
  def calculate_total_price
    return unless quantity && unit_price
    self.total_price = (quantity.to_f || 0) * (unit_price.to_f || 0)
  end
  
  def update_product_stock
    if quantity_changed? && persisted?
      # Restore previous quantity if it was changed
      if quantity_change
        old_quantity = quantity_change[0] || 0
        product.increment!(:quantity, old_quantity)
      end
    end
    
    # Deduct new quantity
    product.decrement!(:quantity, quantity)
  end
  
  def restore_product_stock
    product.increment!(:quantity, quantity)
  end
  
  def update_bill_total
    bill.update!(total_amount: bill.bill_items.sum(:total_price))
    bill.update_status! if bill.customer.present? # Only update status if customer exists
  end
end
