class Payment < ApplicationRecord
  belongs_to :bill
  belongs_to :customer
  belongs_to :user
  
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_date, presence: true
  validates :payment_method, presence: true
  
  before_validation :set_defaults
  after_save :update_bill_status
  after_destroy :update_bill_status
  
  scope :recent, -> { order(payment_date: :desc) }
  
  private
  
  def set_defaults
    self.payment_date ||= Time.current
    self.payment_method ||= 'cash'
  end
  
  def update_bill_status
    bill.update_status!
  end
end
