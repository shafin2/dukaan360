# StockTransfer Model - Manages stock transfers between shops within a business
# Provides audit trail for inventory movements and proper stock management

class StockTransfer < ApplicationRecord
  belongs_to :product
  belongs_to :from_shop, class_name: 'Shop'
  belongs_to :to_shop, class_name: 'Shop'
  belongs_to :initiated_by, class_name: 'User'
  belongs_to :approved_by, class_name: 'User', optional: true
  belongs_to :business # For easier querying

  # Enums
  enum :status, {
    pending: 0,
    approved: 1,
    in_transit: 2,
    completed: 3,
    cancelled: 4,
    rejected: 5
  }

  # Validations
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :reason, presence: true, length: { minimum: 10, maximum: 500 }
  validates :status, presence: true
  
  # Logical validations
  validate :different_shops
  validate :same_business
  validate :sufficient_stock_at_source
  validate :can_only_approve_pending

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :for_business, ->(business) { where(business: business) }
  scope :involving_shop, ->(shop) { where("from_shop_id = ? OR to_shop_id = ?", shop.id, shop.id) }
  
  # Callbacks
  before_validation :set_business
  after_update :process_inventory_changes, if: :saved_change_to_status?

  # Instance methods
  def can_be_approved?
    pending? && sufficient_stock_available?
  end

  def can_be_cancelled?
    pending? || approved?
  end

  def approve!(approver)
    return false unless can_be_approved?
    
    transaction do
      update!(status: 'approved', approved_by: approver, approved_at: Time.current)
      create_inventory_reservation
    end
    
    true
  rescue => e
    errors.add(:base, "Failed to approve transfer: #{e.message}")
    false
  end

  def complete!
    return false unless approved? || in_transit?
    
    transaction do
      # Remove from source shop inventory
      source_inventory = ShopInventory.find_by(shop: from_shop, product: product)
      source_inventory.update!(quantity: source_inventory.quantity - quantity)
      
      # Add to destination shop inventory (create if doesn't exist)
      destination_inventory = ShopInventory.find_or_create_by(
        shop: to_shop, 
        product: product,
        business: business
      ) do |inventory|
        inventory.quantity = 0
        inventory.min_stock_level = product.min_stock_level || 10
        inventory.max_stock_level = product.max_stock_level || 100
        inventory.reorder_point = product.reorder_point || 20
      end
      
      destination_inventory.update!(quantity: destination_inventory.quantity + quantity)
      
      update!(status: 'completed', completed_at: Time.current)
    end
    
    true
  rescue => e
    errors.add(:base, "Failed to complete transfer: #{e.message}")
    false
  end

  def cancel!(reason = nil)
    return false unless can_be_cancelled?
    
    update!(
      status: 'cancelled', 
      cancellation_reason: reason,
      cancelled_at: Time.current
    )
  end

  def status_color
    case status
    when 'pending' then 'text-yellow-600 bg-yellow-50 border-yellow-200'
    when 'approved' then 'text-blue-600 bg-blue-50 border-blue-200'
    when 'in_transit' then 'text-purple-600 bg-purple-50 border-purple-200'
    when 'completed' then 'text-green-600 bg-green-50 border-green-200'
    when 'cancelled' then 'text-gray-600 bg-gray-50 border-gray-200'
    when 'rejected' then 'text-red-600 bg-red-50 border-red-200'
    else 'text-gray-600 bg-gray-50 border-gray-200'
    end
  end

  def transfer_summary
    "#{quantity} #{product.unit} of #{product.name} from #{from_shop.name} to #{to_shop.name}"
  end

  private

  def different_shops
    if from_shop_id.present? && to_shop_id.present? && from_shop_id == to_shop_id
      errors.add(:to_shop, "cannot be the same as source shop")
    end
  end

  def same_business
    if from_shop.present? && to_shop.present? && from_shop.business_id != to_shop.business_id
      errors.add(:base, "can only transfer between shops in the same business")
    end
  end

  def sufficient_stock_at_source
    return unless from_shop.present? && product.present? && quantity.present?
    
    source_inventory = ShopInventory.find_by(shop: from_shop, product: product)
    if source_inventory.nil? || source_inventory.quantity < quantity
      errors.add(:quantity, "insufficient stock at source shop")
    end
  end

  def can_only_approve_pending
    if status_changed? && !status_was == 'pending' && status == 'approved'
      errors.add(:status, "can only approve pending transfers")
    end
  end

  def set_business
    self.business = from_shop.business if from_shop.present?
  end

  def process_inventory_changes
    case status
    when 'completed'
      # Handled in complete! method
    when 'cancelled', 'rejected'
      # Remove any reservations if they exist
      remove_inventory_reservation
    end
  end

  def sufficient_stock_available?
    source_inventory = ShopInventory.find_by(shop: from_shop, product: product)
    source_inventory.present? && source_inventory.quantity >= quantity
  end

  def create_inventory_reservation
    # In a more complex system, we might create a separate reservation record
    # For now, we'll just ensure the stock is available when completing
  end

  def remove_inventory_reservation
    # Remove any inventory reservations if implemented
  end
end
