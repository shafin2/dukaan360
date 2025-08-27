class BillsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_bill, only: [:show, :edit, :update, :mark_as_paid, :cancel]
  before_action :set_customer, only: [:new, :create]
  
  layout 'dashboard'
  
  def index
    @bills = current_user.bills.includes(:customer, :bill_items, :products, :payments)
                         .order(bill_date: :desc)
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
      @products = Product.all
      render :new_cash_bill
    elsif @customer
      # Credit bill for a specific customer
      @bill = @customer.bills.build
      @bill.bill_items.build
      @products = current_user.products.where('quantity > 0')
      render :new
    else
      # No customer or cash bill type - redirect to customer selection
      redirect_to bills_path
    end
  end
  
  def new_cash_bill
    @bill = Bill.new
    @bill.bill_items.build
    @products = current_user.products.where('quantity > 0')
  end
  
  def create
    if params[:bill][:bill_type] == 'cash'
      # Cash bill creation
      @bill = current_user.bills.build(bill_params)
      @bill.user = current_user
      @bill.shop = current_user.shop if current_user.shop
      @bill.bill_type = 'cash'
      
      if @bill.save
        # No need to manually calculate total - it's done in model callbacks
        redirect_to bills_path, notice: 'Cash bill created and recorded successfully.'
      else
        @products = current_user.products.where('quantity > 0')
        render 'new_cash_bill', status: :unprocessable_entity
      end
    else
      # Credit bill creation
      customer = current_user.customers.find(params[:customer_id]) if params[:customer_id].present?
      if customer
        @bill = customer.bills.build(bill_params)
        @bill.user = current_user
        @bill.shop = current_user.shop if current_user.shop
        @bill.bill_type = 'credit'
        
        if @bill.save
          # No need to manually update status - it's done in model callbacks
          redirect_to bill_path(@bill), notice: 'Credit bill created successfully.'
        else
          @customer = customer
          @products = current_user.products.where('quantity > 0')
          render :new, status: :unprocessable_entity
        end
      else
        redirect_to bills_path, alert: 'Customer not found.'
      end
    end
  end
  
  def edit
    @products = current_user.products.where('quantity > 0')
  end
  
  def update
    if @bill.update(bill_params)
      @bill.update!(total_amount: @bill.bill_items.sum(:total_price))
      @bill.update_status!
      redirect_to bill_path(@bill), notice: 'Bill updated successfully.'
    else
      @products = current_user.products.where('quantity > 0')
      render :edit, status: :unprocessable_entity
    end
  end
  
  def mark_as_paid
    remaining_amount = @bill.outstanding_amount
    
    payment = @bill.payments.build(
      customer: @bill.customer,
      user: current_user,
      amount: remaining_amount,
      payment_method: 'cash',
      notes: 'Marked as paid in full'
    )
    
    if payment.save
      redirect_to bill_path(@bill), notice: 'Bill marked as paid.'
    else
      redirect_to bill_path(@bill), alert: 'Failed to mark bill as paid.'
    end
  end
  
  def cancel
    if @bill.update(status: 'cancelled')
      # Restore stock for all items
      @bill.bill_items.each do |item|
        item.product.increment!(:quantity, item.quantity)
      end
      redirect_to bills_path, notice: 'Bill cancelled successfully.'
    else
      redirect_to bill_path(@bill), alert: 'Failed to cancel bill.'
    end
  end
  
  private
  
  def set_bill
    @bill = current_user.bills.find(params[:id])
  end
  
  def set_customer
    @customer = current_user.customers.find(params[:customer_id]) if params[:customer_id]
  end
  
  private

  def bill_params
    params.require(:bill).permit(:customer_id, :bill_type, :due_date, :notes, :amount, 
                                 bill_items_attributes: [:id, :product_id, :quantity, :unit_price, :_destroy])
  end
end
