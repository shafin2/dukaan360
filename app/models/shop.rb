class Shop < ApplicationRecord
  belongs_to :business
  has_many :users, dependent: :destroy
  has_many :shop_inventories, dependent: :destroy
  has_many :products, through: :shop_inventories
  has_many :sales, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :bills, dependent: :destroy
  
  # Stock transfer associations
  has_many :outgoing_transfers, class_name: 'StockTransfer', foreign_key: 'from_shop_id'
  has_many :incoming_transfers, class_name: 'StockTransfer', foreign_key: 'to_shop_id'
  
  validates :name, presence: true
  validates :name, uniqueness: { scope: :business_id, message: "must be unique within the business" }
  
  # Scope for active shops
  scope :active, -> { joins(:business).where(businesses: { active: true }) }
  
  # Inventory management methods
  def total_products_count
    shop_inventories.count
  end
  
  def products_in_stock_count
    shop_inventories.in_stock.count
  end
  
  def products_out_of_stock_count
    shop_inventories.out_of_stock.count
  end
  
  def low_stock_products_count
    shop_inventories.low_stock.count
  end
  
  def total_inventory_value
    shop_inventories.joins(:product).sum('shop_inventories.quantity * products.buying_price')
  end
  
  def can_fulfill_order?(product, requested_quantity)
    inventory = shop_inventories.find_by(product: product)
    inventory.present? && inventory.can_fulfill_quantity?(requested_quantity)
  end
  
  # Get workers for this specific shop
  def shop_workers
    users.where(role: 'shop_worker')
  end
  
  # Get shop managers (business owners can manage any shop in their business)
  def managers
    business.users.where(role: 'business_owner')
  end

  # Ransackable attributes for ActiveAdmin search
  def self.ransackable_attributes(auth_object = nil)
    ["address", "created_at", "id", "name", "settings", "business_id", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["business", "products", "sales", "users", "customers", "bills", "shop_inventories", 
     "outgoing_transfers", "incoming_transfers"]
  end
end
