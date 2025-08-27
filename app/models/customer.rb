class Customer < ApplicationRecord
  belongs_to :user
  belongs_to :shop
  has_many :bills, dependent: :destroy
  has_many :payments, dependent: :destroy
  
  validates :name, presence: true
  validates :total_credit, :total_paid, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  
  before_validation :set_defaults
  
  def outstanding_amount
    (total_credit || 0) - (total_paid || 0)
  end
  
  def has_outstanding?
    outstanding_amount > 0
  end
  
  def payment_status
    if outstanding_amount <= 0
      'paid'
    elsif total_paid > 0
      'partial'
    else
      'pending'
    end
  end
  
  def status_color
    case payment_status
    when 'paid' then 'text-green-600'
    when 'partial' then 'text-orange-600'
    when 'pending' then 'text-red-600'
    end
  end
  
  private
  
  def set_defaults
    self.total_credit = 0 if total_credit.nil?
    self.total_paid = 0 if total_paid.nil?
  end
end
