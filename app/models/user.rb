class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  belongs_to :shop
  has_many :products, foreign_key: :created_by_id, dependent: :destroy
  has_many :sales, dependent: :destroy
  
  # Role enum
  enum :role, { owner: 0, worker: 1 }
  
  validates :name, presence: true

  # Ransackable attributes for ActiveAdmin search
  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "email", "id", "name", "role", "shop_id", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["products", "sales", "shop"]
  end
end
