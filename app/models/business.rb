class Business < ApplicationRecord
  has_many :shops, dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :products, dependent: :destroy  # Products now belong directly to business
  has_many :shop_inventories, dependent: :destroy
  has_many :stock_transfers, dependent: :destroy
  has_many :customers, through: :shops
  has_many :bills, through: :shops
  has_many :sales, through: :shops
  
  validates :name, presence: true, uniqueness: true
  validates :contact_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :primary_color, format: { with: /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/, message: "must be a valid hex color" }
  validates :secondary_color, format: { with: /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/, message: "must be a valid hex color" }
  
  scope :active, -> { where(active: true) }
  scope :recent, -> { order(created_at: :desc) }
  
  # Business inventory management methods
  def total_products_count
    products.count
  end
  
  def total_inventory_value
    shop_inventories.joins(:product).sum('shop_inventories.quantity * products.buying_price')
  end
  
  def products_across_all_shops
    products.joins(:shop_inventories).distinct
  end
  
  def low_stock_products
    products.joins(:shop_inventories).where('shop_inventories.quantity <= shop_inventories.reorder_point')
  end
  
  def out_of_stock_products
    products.joins(:shop_inventories).where('shop_inventories.quantity = 0')
  end
  
  def distribute_inventory_to_shop(product, shop, quantity, user)
    # Create or update shop inventory
    shop_inventory = shop_inventories.find_or_create_by(shop: shop, product: product) do |inventory|
      inventory.quantity = 0
      inventory.min_stock_level = product.minimum_stock_level
      inventory.max_stock_level = product.maximum_stock_level
      inventory.reorder_point = product.reorder_threshold
    end
    
    shop_inventory.restock(quantity, notes: "Initial distribution by #{user.email}")
    shop_inventory
  end
  
  # Get the business owner
  def business_owner
    users.where(role: 'business_owner').first
  end
  
  # Get all business owners (should typically be one per business)
  def business_owners
    users.where(role: 'business_owner')
  end
  
  # Get workers across all shops
  def shop_workers
    users.where(role: 'shop_worker')
  end
  
  # Check if business is active
  def active?
    active
  end
  
  # Ransackable attributes for ActiveAdmin search
  def self.ransackable_attributes(auth_object = nil)
    ["name", "business_type", "contact_email", "contact_phone", "active", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["shops", "users", "products", "customers", "bills", "sales", "shop_inventories", "stock_transfers"]
  end
end
