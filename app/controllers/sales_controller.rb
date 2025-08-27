class SalesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_shop_access
  before_action :set_sale, only: [:show]
  layout 'dashboard'
  
  def index
    @sales = current_user.sales
                        .includes(:product, :user, :bill)
                        .order(created_at: :desc)
                        .paginate(page: params[:page], per_page: 20)
    
    @today_sales = current_user.sales.where(created_at: Date.current.all_day).sum(:total_amount)
    @total_sales = current_user.sales.sum(:total_amount)
  end
  
  def new
    @sale = current_user.sales.build
    @products = current_user.products.where('quantity > 0').order(:name)
  end
  
  def create
    @sale = current_user.sales.build(sale_params)
    @sale.user = current_user
    
    # Check if product has enough stock
    product = current_user.products.find(sale_params[:product_id])
    
    if product.quantity < sale_params[:quantity].to_i
      redirect_to new_sale_path, alert: "Not enough stock! Only #{product.quantity} packs available."
      return
    end
    
    # Calculate total amount
    @sale.total_amount = @sale.quantity * @sale.unit_price
    @sale.sale_date = Time.current
    
    if @sale.save
      # Reduce product quantity
      product.decrement!(:quantity, @sale.quantity)
      
      redirect_to sales_path, notice: "Sale recorded successfully! #{@sale.quantity} packs of #{product.name} sold."
    else
      @products = current_user.products.where('quantity > 0').order(:name)
      render :new, status: :unprocessable_entity
    end
  end
  
  def show
    # Show sale details
  end
  
  private
  
  def set_sale
    @sale = current_user.sales.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to sales_path, alert: 'Sale not found.'
  end
  
  def sale_params
    params.require(:sale).permit(:product_id, :quantity, :unit_price)
  end
  
  def ensure_shop_access
    unless current_user.shop.present?
      redirect_to root_path, alert: 'Access denied. Please contact administrator.'
    end
  end
end
