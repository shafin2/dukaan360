# ShopInventory Model - Manages product stock allocation per shop
# This allows businesses to distribute inventory across multiple shops
# and track stock levels independently

class ShopInventory < ApplicationRecord
  belongs_to :shop
  belongs_to :product
  belongs_to :business # For easier querying and data integrity

  # Validations
  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :min_stock_level, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :max_stock_level, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :reorder_point, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  # Ensure unique product per shop (can't have duplicate entries)
  validates :product_id, uniqueness: { scope: :shop_id, message: "already exists in this shop" }
  
  # Logical validations
  validate :max_greater_than_min
  validate :reorder_point_logical
  validate :business_consistency

  # Scopes
  scope :low_stock, -> { where('shop_inventories.quantity <= shop_inventories.reorder_point') }
  scope :out_of_stock, -> { where('shop_inventories.quantity = 0') }
  scope :in_stock, -> { where('shop_inventories.quantity > 0') }
  scope :overstocked, -> { where('shop_inventories.quantity > shop_inventories.max_stock_level') }

  # Instance methods
  def stock_status
    return 'out_of_stock' if quantity == 0
    return 'low_stock' if quantity <= reorder_point
    return 'overstocked' if quantity > max_stock_level
    'adequate'
  end

  def stock_status_color
    case stock_status
    when 'out_of_stock' then 'text-red-600 bg-red-50 border-red-200'
    when 'low_stock' then 'text-yellow-600 bg-yellow-50 border-yellow-200'
    when 'overstocked' then 'text-blue-600 bg-blue-50 border-blue-200'
    else 'text-green-600 bg-green-50 border-green-200'
    end
  end

  def stock_percentage
    return 0 if max_stock_level == 0
    [(quantity.to_f / max_stock_level * 100).round(1), 100].min
  end

  def days_until_stockout
    # Simple calculation based on average daily usage (if we had sales data)
    # For now, return nil as we don't have historical sales data
    nil
  end

  def can_fulfill_quantity?(requested_quantity)
    quantity >= requested_quantity
  end

  def reserve_stock(requested_quantity)
    if can_fulfill_quantity?(requested_quantity)
      update!(quantity: quantity - requested_quantity)
      true
    else
      false
    end
  end

  def restock(additional_quantity, notes: nil)
    self.quantity += additional_quantity
    self.last_restocked_at = Time.current
    self.restock_notes = notes if notes.present?
    save!
  end

  private

  def max_greater_than_min
    if max_stock_level.present? && min_stock_level.present? && max_stock_level < min_stock_level
      errors.add(:max_stock_level, "must be greater than minimum stock level")
    end
  end

  def reorder_point_logical
    if reorder_point.present? && min_stock_level.present? && reorder_point < min_stock_level
      errors.add(:reorder_point, "should be greater than or equal to minimum stock level")
    end
  end

  def business_consistency
    if shop.present? && product.present? && business.present?
      if shop.business_id != business.id
        errors.add(:business, "must match the shop's business")
      end
      if product.business_id != business.id
        errors.add(:business, "must match the product's business")
      end
    end
  end
end
