class InventoryController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_business_access
  before_action :set_inventory, only: [:show, :edit, :update, :restock]
  layout 'dashboard'
  
  def index
    if current_user.business_admin?
      # Business admin sees inventory across all shops
      @shop_inventories = current_user.business.shop_inventories
                                      .includes(:product, :shop)
                                      .joins(:product)
      @shop_inventories = apply_search_filters(@shop_inventories)
      @shop_inventories = @shop_inventories.paginate(page: params[:page], per_page: 20)
      @shops = current_user.business.shops
    else
      # Workers see only their shop's inventory
      @shop_inventories = current_user.shop.shop_inventories
                                     .includes(:product)
                                     .joins(:product)
      @shop_inventories = apply_search_filters(@shop_inventories)
      @shop_inventories = @shop_inventories.paginate(page: params[:page], per_page: 20)
      @shops = [current_user.shop]
    end
    
    # Summary statistics
    @total_inventory_value = @shop_inventories.joins(:product)
                                             .sum('shop_inventories.quantity * products.buying_price')
    @low_stock_count = @shop_inventories.where('shop_inventories.quantity <= shop_inventories.reorder_point').count
    @out_of_stock_count = @shop_inventories.where('shop_inventories.quantity = 0').count
    @total_products = @shop_inventories.count
    
    @filter_shop = params[:shop_id].present? ? Shop.find(params[:shop_id]) : nil
    @filter_status = params[:status]
    
    # Group by shop for better display
    @inventories_by_shop = @shop_inventories.group_by(&:shop)
  end

  def show
    # Individual inventory item details
  end
  
  def new
    unless current_user.can?('manage_inventory')
      redirect_to inventory_index_path, alert: 'You do not have permission to add inventory.'
      return
    end
    
    @shop_inventory = ShopInventory.new
    @shops = current_user.business_admin? ? current_user.business.shops : [current_user.shop]
    @products = current_user.business.products
  end
  
  def create
    unless current_user.can?('manage_inventory')
      redirect_to inventory_index_path, alert: 'You do not have permission to add inventory.'
      return
    end
    
    @shop_inventory = ShopInventory.new(shop_inventory_params)
    @shop_inventory.business = current_user.business
    
    if @shop_inventory.save
      redirect_to inventory_index_path, notice: 'Stock added successfully.'
    else
      @shops = current_user.business_admin? ? current_user.business.shops : [current_user.shop]
      @products = current_user.business.products
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    unless current_user.can?('manage_inventory')
      redirect_to inventory_index_path, alert: 'You do not have permission to edit inventory.'
      return
    end
  end
  
  def update
    unless current_user.can?('manage_inventory')
      redirect_to inventory_index_path, alert: 'You do not have permission to edit inventory.'
      return
    end
    
    if @inventory.update(inventory_params)
      redirect_to inventory_path(@inventory), 
        notice: 'Inventory updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def restock
    unless current_user.can?('manage_inventory')
      redirect_to inventory_index_path, alert: 'You do not have permission to restock inventory.'
      return
    end
    
    if params[:restock_quantity].present? && params[:restock_quantity].to_i > 0
      quantity = params[:restock_quantity].to_i
      notes = params[:restock_notes]
      
      @inventory.restock(quantity, notes: notes)
      
      redirect_to inventory_path(@inventory),
        notice: "Successfully restocked #{quantity} #{@inventory.product.unit}(s). New total: #{@inventory.quantity}"
    else
      redirect_to inventory_path(@inventory),
        alert: 'Please enter a valid restock quantity.'
    end
  end
  
  def distribute
    unless current_user.business_admin?
      redirect_to inventory_index_path, alert: 'Only business admins can distribute inventory.'
      return
    end
    
    @product = current_user.business.products.find(params[:product_id])
    @shops = current_user.business.shops.active
    @current_allocations = @product.shop_inventories.includes(:shop)
    
    if request.post?
      success = true
      
      ActiveRecord::Base.transaction do
        params[:allocations].each do |shop_id, allocation_data|
          next if allocation_data[:quantity].blank?
          
          shop = current_user.business.shops.find(shop_id)
          inventory = @product.shop_inventories.find_or_initialize_by(shop: shop)
          
          inventory.assign_attributes(
            quantity: allocation_data[:quantity].to_i,
            min_stock_level: allocation_data[:min_stock_level].to_i || @product.min_stock_level,
            max_stock_level: allocation_data[:max_stock_level].to_i || @product.max_stock_level,
            reorder_point: allocation_data[:reorder_point].to_i || @product.reorder_point,
            business: current_user.business
          )
          
          unless inventory.save
            success = false
            raise ActiveRecord::Rollback
          end
        end
      end
      
      if success
        redirect_to inventory_index_path, 
          notice: "Inventory distributed successfully for #{@product.name}"
      else
        render :distribute, status: :unprocessable_entity
      end
    end
  end
  
  def low_stock
    unless current_user.can?('view_inventory')
      redirect_to dashboard_index_path, alert: 'You do not have permission to view inventory reports.'
      return
    end
    
    if current_user.business_admin?
      # Business admin sees low stock across all shops
          @low_stock_items = current_user.business.shop_inventories
                                    .includes(:product, :shop)
                                    .where('shop_inventories.quantity <= shop_inventories.min_stock_level')
                                    .order(:quantity)
    else
      # Workers see low stock in their shop only
      @low_stock_items = current_user.shop.shop_inventories
                                    .joins(:product)
                                    .where('shop_inventories.quantity <= shop_inventories.min_stock_level')
                                    .includes(:product)
                                    .order(:quantity, 'products.name')
    end
    
    @critical_stock = @low_stock_items.where('quantity = 0')
    @warning_stock = @low_stock_items.where('shop_inventories.quantity > 0 AND shop_inventories.quantity <= shop_inventories.min_stock_level')
  end
  
  def stock_report
    unless current_user.can?('view_inventory')
      redirect_to dashboard_index_path, alert: 'You do not have permission to view inventory reports.'
      return
    end
    
    # Date filters
    @start_date = params[:start_date]&.to_date || 30.days.ago
    @end_date = params[:end_date]&.to_date || Date.current
    
    if current_user.business_admin?
      # Business-wide stock report
      @shops = current_user.business.shops.includes(:shop_inventories)
      @total_products = current_user.business.products.count
      @total_stock_value = current_user.business.shop_inventories
                                      .joins(:product)
                                      .sum('quantity * products.selling_price')
      
      # Stock movements in date range
      @stock_movements = StockTransfer.where(business: current_user.business)
                                    .where(created_at: @start_date..@end_date)
                                    .where(status: ['approved', 'completed'])
                                    .includes(:product, :from_shop, :to_shop)
                                    .order(created_at: :desc)
    else
      # Shop-specific stock report
      @shop = current_user.shop
      @total_products = @shop.shop_inventories.count
      @total_stock_value = @shop.shop_inventories
                               .joins(:product)
                               .sum('quantity * products.selling_price')
      
      # Stock movements involving this shop
      @stock_movements = StockTransfer.where(
        "(from_shop_id = ? OR to_shop_id = ?) AND business_id = ?", 
        @shop.id, @shop.id, current_user.business.id
      ).where(created_at: @start_date..@end_date)
       .where(status: ['approved', 'completed'])
       .includes(:product, :from_shop, :to_shop)
       .order(created_at: :desc)
    end
    
    respond_to do |format|
      format.html
      format.csv { 
        send_data generate_stock_report_csv, 
        filename: "stock_report_#{@start_date}_to_#{@end_date}.csv"
      }
    end
  end
  
  def valuation_report
    unless current_user.business_admin?
      redirect_to inventory_index_path, alert: 'Only business admins can view valuation reports.'
      return
    end
    
    @shops = current_user.business.shops.includes(shop_inventories: :product)
    
    @shop_valuations = @shops.map do |shop|
      {
        shop: shop,
        total_items: shop.shop_inventories.sum(:quantity),
        total_value: shop.shop_inventories.joins(:product)
                        .sum('quantity * products.selling_price'),
        cost_value: shop.shop_inventories.joins(:product)
                       .sum('quantity * products.cost_price'),
        products_count: shop.shop_inventories.count
      }
    end
    
    @total_business_value = @shop_valuations.sum { |sv| sv[:total_value] }
    @total_business_cost = @shop_valuations.sum { |sv| sv[:cost_value] }
    @total_items = @shop_valuations.sum { |sv| sv[:total_items] }
  end
  
  def movement_history
    unless current_user.can?('view_inventory')
      redirect_to dashboard_index_path, alert: 'You do not have permission to view movement history.'
      return
    end
    
    @product = current_user.business.products.find(params[:product_id]) if params[:product_id].present?
    @shop = current_user.business.shops.find(params[:shop_id]) if params[:shop_id].present?
    
    # Base query for stock movements
    movements = StockTransfer.where(business: current_user.business)
    
    # Filter by product if specified
    movements = movements.where(product: @product) if @product
    
    # Filter by shop involvement
    if @shop
      movements = movements.where("from_shop_id = ? OR to_shop_id = ?", @shop.id, @shop.id)
    elsif !current_user.business_admin?
      # Non-admin users only see movements involving their shop
      movements = movements.where("from_shop_id = ? OR to_shop_id = ?", 
                                 current_user.shop.id, current_user.shop.id)
    end
    
    @movements = movements.includes(:product, :from_shop, :to_shop, :initiated_by, :approved_by)
                         .order(created_at: :desc)
                         .paginate(page: params[:page], per_page: 25)
    
    # Available filters for dropdowns
    if current_user.business_admin?
      @available_products = current_user.business.products
      @available_shops = current_user.business.shops
    else
      @available_products = current_user.business.products
                                       .joins(:shop_inventories)
                                       .where(shop_inventories: { shop: current_user.shop })
                                       .distinct
      @available_shops = []
    end
  end
  
  def export_csv
    unless current_user.can?('view_inventory')
      redirect_to inventory_index_path, alert: 'You do not have permission to export inventory data.'
      return
    end
    
    filename = if current_user.business_admin?
      "business_inventory_#{Date.current}.csv"
    else
      "#{current_user.shop.name.parameterize}_inventory_#{Date.current}.csv"
    end
    
    send_data generate_inventory_csv, filename: filename
  end
  
  private
  
  def set_inventory
    if current_user.business_admin?
      @inventory = current_user.business.shop_inventories.find(params[:id])
    else
      @inventory = current_user.shop.shop_inventories.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to inventory_index_path, alert: 'Inventory item not found or access denied.'
  end
  
  def inventory_params
    params.require(:shop_inventory).permit(
      :quantity, :min_stock_level, :max_stock_level, :reorder_point
    )
  end
  
  def search_params
    params.permit(:search, :shop_id, :status, :sort_by, :sort_direction)
  end
  
  def ensure_business_access
    unless current_user.business.present?
      redirect_to root_path, alert: 'Access denied. Please contact administrator.'
    end
  end
  
  def generate_inventory_csv
    require 'csv'
    
    CSV.generate(headers: true) do |csv|
      if current_user.business_admin?
        # Business-wide inventory export
        csv << ['Product', 'Shop', 'Quantity', 'Min Stock', 'Cost Price', 'Selling Price', 'Total Value']
        
        current_user.business.shop_inventories
                   .joins(:product, :shop)
                   .order('shops.name', 'products.name')
                   .find_each do |inventory|
          csv << [
            inventory.product.name,
            inventory.shop.name,
            inventory.quantity,
            inventory.min_stock_level,
            inventory.product.cost_price,
            inventory.product.selling_price,
            inventory.quantity * inventory.product.selling_price
          ]
        end
      else
        # Shop-specific inventory export
        csv << ['Product', 'Quantity', 'Min Stock', 'Cost Price', 'Selling Price', 'Total Value']
        
        current_user.shop.shop_inventories
                   .joins(:product)
                   .order('products.name')
                   .find_each do |inventory|
          csv << [
            inventory.product.name,
            inventory.quantity,
            inventory.min_stock_level,
            inventory.product.cost_price,
            inventory.product.selling_price,
            inventory.quantity * inventory.product.selling_price
          ]
        end
      end
    end
  end
  
  def generate_stock_report_csv
    require 'csv'
    
    CSV.generate(headers: true) do |csv|
      csv << ['Date', 'Product', 'From Shop', 'To Shop', 'Quantity', 'Status', 'Initiated By']
      
      @stock_movements.each do |movement|
        csv << [
          movement.created_at.strftime('%Y-%m-%d'),
          movement.product.name,
          movement.from_shop.name,
          movement.to_shop.name,
          movement.quantity,
          movement.status.humanize,
          movement.initiated_by.name
        ]
      end
    end
  end

  private

  def shop_inventory_params
    params.require(:shop_inventory).permit(:shop_id, :product_id, :quantity, :low_stock_threshold)
  end

  def apply_search_filters(inventories)
    if params[:search].present?
      inventories = inventories.where("products.name ILIKE ? OR products.sku ILIKE ?", 
                                     "%#{params[:search]}%", "%#{params[:search]}%")
    end
    
    if params[:shop_id].present? && current_user.business_admin?
      inventories = inventories.where(shop_id: params[:shop_id])
    end
    
    if params[:status].present?
      case params[:status]
      when 'low_stock'
        inventories = inventories.where('shop_inventories.quantity <= shop_inventories.min_stock_level')
      when 'out_of_stock'
        inventories = inventories.where('shop_inventories.quantity = 0')
      when 'overstocked'
        inventories = inventories.where('shop_inventories.quantity > shop_inventories.max_stock_level')
      end
    end
    
    inventories.order('products.name ASC')
  end
end
