class InventoryController < ApplicationController
  before_action :authenticate_user!
  
  layout 'dashboard'
  
  def index
    @products = current_user.products.includes(:sales)
    @low_stock_products = @products.select { |p| p.quantity <= p.minimum_stock_level }
    @out_of_stock_products = @products.where(quantity: 0)
    @expiring_products = @products.select { |p| p.expiry_status.in?(['critical', 'warning']) }
    @expired_products = @products.select { |p| p.expiry_status == 'expired' }
    
    @total_inventory_value = @products.sum { |p| p.quantity * p.buying_price }
    @total_profit_potential = @products.sum { |p| p.quantity * (p.selling_price - p.buying_price) }
    
    # Recent stock movements
    @recent_sales = current_user.sales.includes(:product).order(created_at: :desc).limit(10)
    
    # Group products by category if available
    @products_by_category = @products.group_by(&:category)
    
    # Stock statistics
    @total_products = @products.count
    @in_stock_products = @products.select { |p| p.quantity > 0 }.count
    @categories_count = @products.pluck(:category).compact.uniq.count
  end
end
