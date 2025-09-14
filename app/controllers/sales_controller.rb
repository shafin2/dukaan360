class SalesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_shop_worker
  before_action :set_sale, only: [:show]
  layout 'dashboard'
  
  include ActionView::Helpers::NumberHelper
  
  def index
    @sales = current_user.sales
                        .includes(:product, :user, :bill)
                        .order(created_at: :desc)
                        .paginate(page: params[:page], per_page: 20)
    
    @today_sales = current_user.sales.where(created_at: Date.current.all_day).sum(:total_amount)
    @total_sales = current_user.sales.sum(:total_amount)
    @this_month_sales = current_user.sales.where(created_at: Date.current.beginning_of_month..Date.current.end_of_month).sum(:total_amount)
  end
  
  def new
    @sale = current_user.sales.build
    # Get products available in current user's shop with stock
    @products = current_user.business.products
                           .joins(:shop_inventories)
                           .where(shop_inventories: { shop: current_user.shop, quantity: 1.. })
                           .includes(:shop_inventories)
                           .order(:name)
  end
  
  def create
    @sale = current_user.sales.build(sale_params)
    @sale.user = current_user
    
    # Get product from user's shop inventory
    shop_inventory = current_user.shop.shop_inventories
                                     .joins(:product)
                                     .where(products: { id: sale_params[:product_id] })
                                     .first
    
    unless shop_inventory
      redirect_to new_sale_path, alert: "Product not found in your shop inventory."
      return
    end
    
    product = shop_inventory.product
    quantity = sale_params[:quantity].to_i
    
    if shop_inventory.quantity < quantity
      redirect_to new_sale_path, alert: "Not enough stock! Only #{shop_inventory.quantity} #{product.unit}(s) available."
      return
    end
    
    # Calculate total amount
    @sale.total_amount = @sale.quantity * @sale.unit_price
    @sale.sale_date = Time.current
    
    ActiveRecord::Base.transaction do
      if @sale.save
        # Reduce shop inventory quantity
        shop_inventory.decrement!(:quantity, quantity)
        
        redirect_to sales_path, notice: "Sale recorded successfully! #{quantity} #{product.unit}(s) of #{product.name} sold for Rs #{@sale.total_amount.to_i}."
      else
        @products = current_user.business.products
                               .joins(:shop_inventories)
                               .where(shop_inventories: { shop: current_user.shop, quantity: 1.. })
                               .includes(:shop_inventories)
                               .order(:name)
        render :new, status: :unprocessable_entity
      end
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
  
  def ensure_shop_worker
    unless current_user.shop_worker? && current_user.shop.present?
      redirect_to dashboard_index_path, alert: 'Access denied. Sales functionality is only available to shop workers.'
    end
  end
end
