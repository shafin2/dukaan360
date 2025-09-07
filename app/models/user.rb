class User < ApplicationRecord
  include Authorizable
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  belongs_to :business, optional: true
  belongs_to :shop, optional: true
  has_many :products, foreign_key: :created_by_id, dependent: :destroy
  has_many :sales, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :bills, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :user_permissions, dependent: :destroy
  has_many :permissions, through: :user_permissions
  
  # Updated role enum for new structure
  enum :role, { 
    super_admin: 0,      # System admin who manages businesses
    business_admin: 1,   # Business owner who manages their business
    worker: 2           # Shop worker with limited permissions
  }
  
  validates :name, presence: true
  
  # Role-based validations
  validates :business_id, presence: true, unless: :super_admin?
  validates :shop_id, presence: true, if: :worker?
  
  # Scope methods for easy querying
  scope :for_business, ->(business) { where(business: business) }
  scope :for_shop, ->(shop) { where(shop: shop) }
  
  # Helper methods for role checking
  def can_manage_business?
    super_admin? || business_admin?
  end
  
  def can_manage_multiple_shops?
    super_admin? || business_admin?
  end
  
  def assigned_shops
    if super_admin?
      Shop.all
    elsif business_admin?
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
