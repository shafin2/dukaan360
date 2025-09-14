class User < ApplicationRecord
  include Authorizable
  
  # Include default devise modules. Registration disabled - only admins create accounts
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable
  
  belongs_to :business
  belongs_to :shop, optional: true  # Only shop_workers have shops
  has_many :products, foreign_key: :created_by_id, dependent: :destroy
  has_many :sales, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :bills, dependent: :destroy
  has_many :payments, dependent: :destroy
  
  # Remove complex permission associations - we'll use simple role-based permissions
  # has_many :user_permissions, dependent: :destroy
  # has_many :permissions, through: :user_permissions
  
  # Simple 2-role system as per requirements
  enum :role, { 
    business_owner: 0,   # Business owner who manages their business
    shop_worker: 1       # Shop worker with limited permissions to their shop only
  }
  
  validates :name, presence: true
  
  # Role-based validations
  validates :business_id, presence: true
  validates :shop_id, presence: true, if: :shop_worker?
  validates :shop_id, absence: true, if: :business_owner?
  
  # Scope methods for easy querying
  scope :for_business, ->(business) { where(business: business) }
  scope :for_shop, ->(shop) { where(shop: shop) }
  scope :recent, -> { order(created_at: :desc) }
  
  # Helper methods for role checking
  def can_manage_business?
    business_owner?
  end
  
  def can_manage_multiple_shops?
    business_owner?
  end
  
  def assigned_shops
    if business_owner?
      business&.shops || Shop.none
    else
      shop ? [shop] : []
    end
  end

  # Ransackable attributes for ActiveAdmin search
  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "email", "id", "name", "role", "shop_id", "business_id", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["business", "products", "sales", "shop", "customers", "bills", "payments"]
  end
end
