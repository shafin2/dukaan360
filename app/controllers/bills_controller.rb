class BillsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_shop_worker
  before_action :set_bill, only: [:show, :edit, :update, :destroy]
  before_action :set_customer, only: [:new, :create]
  
  layout 'dashboard'
  
  def index
    @bills = current_user.bills.includes(:customer, :bill_items, :products, :payments)
                         .order(bill_date: :desc)
                         .paginate(page: params[:page], per_page: 20)
    @pending_bills = @bills.where(status: ['pending', 'partial'])
    @total_receivables = @pending_bills.sum { |bill| bill.outstanding_amount }
  end
  
  def show
    @payments = @bill.payments.includes(:user).order(payment_date: :desc)
    @new_payment = @bill.payments.build
  end
  
  def new
    if params[:bill_type] == 'cash'
      @bill = Bill.new
      @bill.bill_items.build # Add one empty bill item
      @products = get_available_products
      render :new_cash_bill
    elsif @customer
      # Credit bill for a specific customer
      @bill = @customer.bills.build
      @bill.bill_items.build
      @products = get_available_products
      render :new
    else
      # No customer or cash bill type - redirect to customer selection
      redirect_to bills_path
    end
  end
  
  def new_cash_bill
    @bill = Bill.new
    @bill.bill_items.build
    @products = get_available_products
  end
  
  def create
    if params[:bill][:bill_type] == 'cash'
      # Cash bill creation
      @bill = current_user.bills.build(bill_params)
      @bill.user = current_user
      @bill.shop = current_user.shop
      @bill.bill_type = 'cash'
      @bill.status = 'cash'
      
      if validate_and_process_bill(@bill)
        redirect_to bill_path(@bill), notice: 'Cash bill created successfully.'
      else
        @products = get_available_products
        render :new_cash_bill, status: :unprocessable_entity
      end
    else
      # Credit bill creation
      @bill = @customer.bills.build(bill_params)
      @bill.user = current_user
      @bill.shop = current_user.shop
      @bill.bill_type = 'credit'
      
      if validate_and_process_bill(@bill)
        redirect_to bill_path(@bill), notice: 'Credit bill created successfully.'
      else
        @products = get_available_products
        render :new, status: :unprocessable_entity
      end
    end
  end
  
  def edit
    # Edit bill
  end
  
  def update
    if @bill.update(bill_params)
      redirect_to bill_path(@bill), notice: 'Bill updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @bill.destroy
    redirect_to bills_path, notice: 'Bill deleted successfully.'
  end
  
  private
  
  def set_bill
    @bill = current_user.bills.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to bills_path, alert: 'Bill not found.'
  end
  
  def set_customer
    @customer = current_user.customers.find(params[:customer_id]) if params[:customer_id]
  rescue ActiveRecord::RecordNotFound
    redirect_to customers_path, alert: 'Customer not found.'
  end
  
  def bill_params
    params.require(:bill).permit(:bill_type, :due_date, :notes, 
      bill_items_attributes: [:id, :product_id, :quantity, :unit_price, :_destroy])
  end
  
  def get_available_products
    current_user.business.products
                .joins(:shop_inventories)
                .where(shop_inventories: { shop: current_user.shop, quantity: 1.. })
                .includes(:shop_inventories)
                .order(:name)
  end
  
  def validate_and_process_bill(bill)
    # Validate inventory before saving
    bill.bill_items.each do |item|
      next if item.marked_for_destruction?
      
      shop_inventory = current_user.shop.shop_inventories
                                       .joins(:product)
                                       .where(products: { id: item.product_id })
                                       .first
      
      unless shop_inventory
        bill.errors.add(:base, "Product not found in your shop inventory")
        return false
      end
      
      if shop_inventory.quantity < item.quantity
        product_name = shop_inventory.product.name
        bill.errors.add(:base, "Not enough stock for #{product_name}! Only #{shop_inventory.quantity} available.")
        return false
      end
    end
    
    ActiveRecord::Base.transaction do
      if bill.save
        # Reduce inventory for each item
        bill.bill_items.each do |item|
          shop_inventory = current_user.shop.shop_inventories
                                           .joins(:product)
                                           .where(products: { id: item.product_id })
                                           .first
          shop_inventory.decrement!(:quantity, item.quantity)
        end
        true
      else
        false
      end
    end
  end
  
  def ensure_shop_worker
    unless current_user.shop_worker? && current_user.shop.present?
      redirect_to dashboard_index_path, alert: 'Access denied. Bills functionality is only available to shop workers.'
    end
  end
end
