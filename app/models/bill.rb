class Bill < ApplicationRecord
  belongs_to :customer, optional: true  # Optional for cash bills
  belongs_to :user
  belongs_to :shop, optional: true
  has_many :bill_items, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :products, through: :bill_items
  has_many :sales, dependent: :nullify  # When bill is deleted, sales remain but bill_id becomes null
  
  accepts_nested_attributes_for :bill_items, allow_destroy: true, reject_if: :all_blank
  
  validates :bill_number, presence: true, uniqueness: { scope: [:shop_id, :user_id] }
  validates :total_amount, numericality: { greater_than: 0 }, allow_nil: false
  validates :status, inclusion: { in: %w[pending partial paid cancelled cash] }
  validates :bill_date, presence: true
  validates :bill_type, inclusion: { in: %w[cash credit] }
  
  before_validation :set_defaults, :generate_bill_number, :calculate_total_amount, on: :create
  after_create :process_cash_bill_if_needed
  
  scope :pending, -> { where(status: ['pending', 'partial']) }
  scope :paid, -> { where(status: 'paid') }
  scope :cash_bills, -> { where(bill_type: 'cash') }
  scope :credit_bills, -> { where(bill_type: 'credit') }
  scope :recent, -> { order(bill_date: :desc) }
  
  def cash_bill?
    bill_type == 'cash'
  end
  
  def credit_bill?
    bill_type == 'credit'
  end
  
  def total_paid
    payments.sum(:amount)
  end
  
  def outstanding_amount
    # Cash bills are always fully paid
    return 0.0 if cash_bill?
    total_amount - total_paid
  end
  
  def update_status!
    return unless customer # Skip status update for cash bills without customers
    
    paid_amount = total_paid
    old_status = status
    new_status = if paid_amount >= total_amount
                   'paid'
                 elsif paid_amount > 0
                   'partial'
                 else
                   'pending'
                 end
    
    update!(status: new_status)
    
    # Create sales entries when bill becomes fully paid
    if old_status != 'paid' && new_status == 'paid'
      create_sales_entries_for_credit_bill
    end
    
    # Update customer totals
    customer.update!(
      total_credit: customer.bills.sum(:total_amount),
      total_paid: customer.payments.sum(:amount)
    )
  end
  
  def status_color
    case status
    when 'paid' then 'text-green-600'
    when 'partial' then 'text-orange-600'
    when 'pending' then 'text-red-600'
    when 'cancelled' then 'text-gray-600'
    end
  end
  
  private
  
  def generate_bill_number
    return if bill_number.present?
    
    # Simple timestamp-based bill number to avoid conflicts
    timestamp = Time.current.strftime("%y%m%d%H%M%S")
    random_suffix = rand(100..999)
    
    if shop && shop.name.present?
      # Use first 2 letters of shop name
      shop_code = shop.name.upcase.gsub(/[^A-Z]/, '')[0..1] || "SH"
      self.bill_number = "#{shop_code}#{timestamp}#{random_suffix}"
    else
      self.bill_number = "BL#{timestamp}#{random_suffix}"
    end
    
    # Ensure uniqueness by checking if it already exists
    while Bill.exists?(bill_number: self.bill_number)
      random_suffix = rand(100..999)
      if shop && shop.name.present?
        shop_code = shop.name.upcase.gsub(/[^A-Z]/, '')[0..1] || "SH"
        self.bill_number = "#{shop_code}#{timestamp}#{random_suffix}"
      else
        self.bill_number = "BL#{timestamp}#{random_suffix}"
      end
    end
  end
  
  def set_defaults
    self.bill_date ||= Time.current
    self.status ||= (bill_type == 'cash' ? 'cash' : 'pending')
    self.bill_type ||= 'credit'
  end
  
  def calculate_total_amount
    # Skip calculation if no bill items are present yet
    return self.total_amount = 0.01 if bill_items.empty?
    
    if new_record? && bill_items.any?
      # For new records with bill_items attributes, calculate from the attributes
      calculated_total = bill_items.sum { |item| 
        next 0 unless item.quantity && item.unit_price
        quantity = item.quantity.to_f
        unit_price = item.unit_price.to_f
        quantity * unit_price
      }
    elsif bill_items.loaded?
      # Use loaded bill_items if available
      calculated_total = bill_items.sum { |item| (item.quantity.to_f || 0) * (item.unit_price.to_f || 0) }
    else
      # Query database for bill_items
      calculated_total = bill_items.sum('quantity * unit_price')
    end
    
    self.total_amount = calculated_total > 0 ? calculated_total : 0.01 # Minimum valid amount
  end
  
  def process_cash_bill_if_needed
    return unless cash_bill?
    
    # For cash bills, immediately create sales entries for each item
    bill_items.each do |item|
      Sale.create!(
        product: item.product,
        user: user,
        quantity: item.quantity,
        unit_price: item.unit_price,
        total_amount: item.total_price,
        sale_date: bill_date,
        bill: self
      )
    end
    
    # Mark bill as paid since it's cash
    update_column(:status, 'cash')
  end
  
  def create_sales_entries_for_credit_bill
    # Only create sales if they don't already exist for this bill
    return if sales.exists?
    
    bill_items.each do |item|
      Sale.create!(
        product: item.product,
        user: user,
        quantity: item.quantity,
        unit_price: item.unit_price,
        total_amount: item.total_price,
        sale_date: Time.current, # Use current date when payment is completed
        bill: self
      )
    end
  end
end
