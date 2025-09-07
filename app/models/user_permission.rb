class UserPermission < ApplicationRecord
  belongs_to :user
  belongs_to :permission
  belongs_to :shop, optional: true
  
  validates :user_id, uniqueness: { scope: [:permission_id, :shop_id] }
  
  scope :granted, -> { where(granted: true) }
  scope :revoked, -> { where(granted: false) }
  scope :for_shop, ->(shop) { where(shop: shop) }
  scope :global, -> { where(shop: nil) }
  
  # Check if permission is granted for specific shop or globally
  def self.has_permission?(user, permission_name, shop = nil)
    permission = Permission.find_by(name: permission_name)
    return false unless permission
    
    # Check shop-specific permission first
    if shop
      user_perm = find_by(user: user, permission: permission, shop: shop)
      return user_perm&.granted? if user_perm
    end
    
    # Check global permission
    global_perm = find_by(user: user, permission: permission, shop: nil)
    global_perm&.granted? || false
  end
  
  def shop_name
    shop&.name || 'All Shops'
  end
  
  # Ransackable attributes for ActiveAdmin search
  def self.ransackable_attributes(auth_object = nil)
    ["user_id", "permission_id", "shop_id", "granted", "notes", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["user", "permission", "shop"]
  end
end
