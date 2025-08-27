class Shop < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :sales, through: :products
  has_many :customers, dependent: :destroy
  has_many :bills, dependent: :destroy
  
  validates :name, presence: true, uniqueness: true

  # Ransackable attributes for ActiveAdmin search
  def self.ransackable_attributes(auth_object = nil)
    ["address", "created_at", "id", "name", "settings", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["products", "sales", "users", "customers", "bills"]
  end
end
