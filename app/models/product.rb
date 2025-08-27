class Product < ApplicationRecord
  include ProductSearchable
  
  belongs_to :shop
  belongs_to :user, foreign_key: :created_by_id
  has_many :sales, dependent: :destroy
  
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :buying_price, :selling_price, presence: true, numericality: { greater_than: 0 }
  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :expiry_date, presence: true
  
  # Custom validations
  validate :selling_price_must_be_greater_than_buying_price
  validate :expiry_date_must_be_future, if: :expiry_date?
  
  # Scopes for dashboard
  scope :in_stock, -> { where('quantity > 0') }
  scope :out_of_stock, -> { where(quantity: 0) }
  scope :expiring_soon, -> { where(expiry_date: Date.current..Date.current + 30.days) }
  scope :expired, -> { where('expiry_date < ?', Date.current) }
  scope :expiring_critical, -> { where(expiry_date: Date.current..Date.current + 15.days) }

  # Ransackable attributes for ActiveAdmin search
  def self.ransackable_attributes(auth_object = nil)
    ["buying_price", "category", "created_at", "created_by_id", "expiry_date", "id", "name", "quantity", "selling_price", "shop_id", "updated_at", "image_url"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["sales", "shop", "user"]
  end
  
  # Instance methods
  def quantity_in_packs
    quantity
  end
  
  def minimum_stock_level
    5 # Default minimum stock level for wholesale
  end
  
  def profit_margin
    return 0 if buying_price.zero?
    ((selling_price - buying_price) / buying_price * 100).round(2)
  end
  
  def stock_status
    return 'out_of_stock' if quantity.zero?
    return 'low_stock' if quantity <= 5  # For wholesale, 5 packs is low
    'in_stock'
  end
  
  def expiry_status
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
    else
      'bg-green-100 text-green-800 border-green-200'
    end
  end
  
  def days_to_expiry
    return 0 if expiry_date < Date.current
    (expiry_date - Date.current).to_i
  end
  
  private
  
  def selling_price_must_be_greater_than_buying_price
    return unless buying_price.present? && selling_price.present?
    
    if selling_price <= buying_price
      errors.add(:selling_price, 'must be greater than buying price')
    end
  end
  
  def expiry_date_must_be_future
    if expiry_date < Date.current
      errors.add(:expiry_date, 'must be a future date')
    end
  end
end
