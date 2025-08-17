class Product < ApplicationRecord
  belongs_to :shop
  belongs_to :user, foreign_key: :created_by_id
  has_many :sales, dependent: :destroy
  
  validates :name, presence: true
  validates :category, presence: true
  validates :buying_price, :selling_price, presence: true, numericality: { greater_than: 0 }
  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Ransackable attributes for ActiveAdmin search
  def self.ransackable_attributes(auth_object = nil)
    ["buying_price", "category", "created_at", "created_by_id", "expiry_date", "id", "name", "quantity", "selling_price", "shop_id", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["sales", "shop", "user"]
  end
end
