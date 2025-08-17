class Sale < ApplicationRecord
  belongs_to :product
  belongs_to :user
  
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, :total_amount, presence: true, numericality: { greater_than: 0 }
  
  before_save :calculate_total
  
  # Ransackable attributes for ActiveAdmin search
  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "product_id", "quantity", "sale_date", "total_amount", "unit_price", "updated_at", "user_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["product", "user"]
  end
  
  private
  
  def calculate_total
    self.total_amount = quantity * unit_price if quantity && unit_price
  end
end
