class CustomersController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_shop_worker
  before_action :set_customer, only: [:show, :edit, :update, :destroy]
  
  layout 'dashboard'
  
  def index
    @customers = current_user.customers.includes(:bills, :payments)
                            .order(:name)
                            .paginate(page: params[:page], per_page: 20)
    @pending_customers = @customers.joins(:bills).where(bills: { status: ['pending', 'partial'] }).distinct
    @total_receivables = @pending_customers.sum(&:outstanding_amount)
  end
  
  def show
    @bills = @customer.bills.includes(:bill_items, :payments).order(bill_date: :desc)
    @total_outstanding = @customer.outstanding_amount
  end
  
  def new
    @customer = current_user.customers.build
  end
  
  def create
    @customer = current_user.customers.build(customer_params)
    @customer.shop = current_user.shop
    
    if @customer.save
      redirect_to customers_path, notice: 'Customer created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @customer.update(customer_params)
      redirect_to customer_path(@customer), notice: 'Customer updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    if @customer.bills.any?
      redirect_to customer_path(@customer), alert: 'Cannot delete customer with existing bills.'
    else
      @customer.destroy
      redirect_to customers_path, notice: 'Customer deleted successfully.'
    end
  end
  
  private
  
  def set_customer
    @customer = current_user.customers.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to customers_path, alert: 'Customer not found.'
  end
  
  def customer_params
    params.require(:customer).permit(:name, :email, :phone, :address, :notes)
  end
  
  def ensure_shop_worker
    unless current_user.shop_worker? && current_user.shop.present?
      redirect_to dashboard_index_path, alert: 'Access denied. Customer management is only available to shop workers.'
    end
  end
end
