class Product < ApplicationRecord
  include ProductSearchable
  
  # Updated associations for business-wide inventory
  belongs_to :business  # Products now belong to business (shared across shops)
  belongs_to :user, foreign_key: :created_by_id, optional: true  # Make user optional
  has_many :shop_inventories, dependent: :destroy
  has_many :shops, through: :shop_inventories
  has_many :sales, dependent: :destroy
  has_many :stock_transfers, dependent: :destroy
  
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :buying_price, :selling_price, presence: true, numericality: { greater_than: 0 }
  validates :business, presence: true
  
  # Default stock settings (can be overridden at shop level)
  validates :min_stock_level, presence: true, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :max_stock_level, presence: true, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :reorder_point, presence: true, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  
  # Expiry date is optional for non-perishable items
  validates :expiry_date, presence: true, if: :requires_expiry_date?
  
  # Custom validations
  validate :selling_price_must_be_greater_than_buying_price
  validate :expiry_date_must_be_future, if: :expiry_date?
  
  # Scopes for dashboard - now based on shop inventories
  scope :in_stock, -> { joins(:shop_inventories).where('shop_inventories.quantity > 0') }
  scope :out_of_stock, -> { joins(:shop_inventories).where('shop_inventories.quantity = 0') }
  scope :expiring_soon, -> { where(expiry_date: Date.current..Date.current + 30.days) }
  scope :expired, -> { where('expiry_date < ?', Date.current) }
  scope :expiring_critical, -> { where(expiry_date: Date.current..Date.current + 15.days) }
  scope :for_business, ->(business) { where(business: business) }

  # Ransackable attributes for ActiveAdmin search
  def self.ransackable_attributes(auth_object = nil)
    ["buying_price", "category", "created_at", "created_by_id", "expiry_date", "id", "name", 
     "selling_price", "business_id", "updated_at", "image_url", "min_stock_level", 
     "max_stock_level", "reorder_point", "unit"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["sales", "shop_inventories", "shops", "business", "user", "stock_transfers"]
  end
  
  # Instance methods - updated for business-wide inventory
  def total_quantity_across_shops
    shop_inventories.sum(:quantity)
  end
  
  def total_business_inventory
    (business_inventory_quantity || 0) + total_quantity_across_shops
  end
  
  def unassigned_inventory
    business_inventory_quantity || 0
  end
  
  def assigned_inventory
    total_quantity_across_shops
  end
  
  def can_assign_to_shop?(quantity)
    unassigned_inventory >= quantity
  end
  
  def assign_to_shop(shop, quantity, user = nil)
    return false unless can_assign_to_shop?(quantity)
    
    ActiveRecord::Base.transaction do
      # Reduce business inventory
      self.update!(business_inventory_quantity: business_inventory_quantity - quantity)
      
      # Add to shop inventory
      shop_inventory = shop_inventories.find_or_initialize_by(shop: shop, business: business)
      if shop_inventory.persisted?
        shop_inventory.update!(quantity: shop_inventory.quantity + quantity)
      else
        shop_inventory.assign_attributes(
          quantity: quantity,
          min_stock_level: min_stock_level,
          max_stock_level: max_stock_level,
          reorder_point: reorder_point,
          business: business
        )
        shop_inventory.save!
      end
    end
    
    true
  rescue => e
    false
  end
  
  def quantity_in_shop(shop)
    inventory = shop_inventories.find_by(shop: shop)
    inventory&.quantity || 0
  end
  
  def stock_status_in_shop(shop)
    inventory = shop_inventories.find_by(shop: shop)
    inventory&.stock_status || 'not_available'
  end
  
  def is_available_in_shop?(shop)
    quantity_in_shop(shop) > 0
  end
  
  def shops_with_stock
    shops.joins(:shop_inventories).where('shop_inventories.quantity > 0')
  end
  
  def shops_out_of_stock
    shops.joins(:shop_inventories).where('shop_inventories.quantity = 0')
  end
  
  def minimum_stock_level
    min_stock_level || 5 # Default minimum stock level
  end
  
  def maximum_stock_level
    max_stock_level || 100 # Default maximum stock level
  end
  
  def reorder_threshold
    reorder_point || 20 # Default reorder point
  end
  
  def profit_margin
    return 0 if buying_price.zero?
    ((selling_price - buying_price) / buying_price * 100).round(2)
  end
  
  def stock_status
    total_qty = total_quantity_across_shops
    return 'out_of_stock' if total_qty.zero?
    return 'low_stock' if total_qty <= minimum_stock_level
    'in_stock'
  end
  
  def overall_stock_status_color
    case stock_status
    when 'out_of_stock' then 'bg-red-100 text-red-800 border-red-200'
    when 'low_stock' then 'bg-yellow-100 text-yellow-800 border-yellow-200'
    else 'bg-green-100 text-green-800 border-green-200'
    end
  end
  
  def expiry_status
    return 'no_expiry' unless expiry_date.present?
    return 'expired' if expiry_date < Date.current
    return 'critical' if expiry_date <= Date.current + 15.days  # Critical: 15 days or less
    return 'warning' if expiry_date <= Date.current + 30.days   # Warning: 30 days or less
    'fresh'
  end
  
  def expiry_color_class
    case expiry_status
    when 'expired', 'critical'
      'bg-red-100 text-red-800 border-red-200'
    when 'warning'
      'bg-yellow-100 text-yellow-800 border-yellow-200'
    when 'no_expiry'
      'bg-blue-100 text-blue-800 border-blue-200'
    else
      'bg-green-100 text-green-800 border-green-200'
    end
  end
  
  def days_to_expiry
    return nil unless expiry_date.present?
    return 0 if expiry_date < Date.current
    (expiry_date - Date.current).to_i
  end
  
  private
  
  def requires_expiry_date?
    # Categories that require expiry dates (perishable items)
    perishable_categories = ['grains', 'oil', 'flour', 'sweeteners', 'dairy', 'meat', 'vegetables', 
                           'fruits', 'snacks', 'beverages', 'medicine', 'food', 'grocery']
    
    return false unless category.present?
    perishable_categories.any? { |cat| category.downcase.include?(cat.downcase) }
  end
  
  def selling_price_must_be_greater_than_buying_price
    return unless buying_price.present? && selling_price.present?
    
    if selling_price <= buying_price
      errors.add(:selling_price, 'must be greater than buying price')
    end
  end
  
  def expiry_date_must_be_future
    if expiry_date && expiry_date < Date.current
      errors.add(:expiry_date, 'must be a future date')
    end
  end
end
