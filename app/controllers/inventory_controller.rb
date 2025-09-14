class InventoryController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_business_owner
  before_action :set_inventory, only: [:show, :edit, :update, :restock]
  layout 'dashboard'
  
  def index
    # Business owner sees all products with their inventory status
    @products = current_user.business.products.includes(:shop_inventories, :shops)
    @products = apply_product_search_filters(@products)
    @products = @products.paginate(page: params[:page], per_page: 20)
    
    @shops = current_user.business.shops
    
    # Summary statistics
    @total_business_inventory = current_user.business.products.sum(:business_inventory_quantity)
    @total_shop_inventory = current_user.business.shop_inventories.sum(:quantity)
    @total_inventory_value = calculate_total_inventory_value
    @low_stock_count = current_user.business.shop_inventories.where('quantity <= min_stock_level').count
    @unassigned_products_count = current_user.business.products.where('business_inventory_quantity > 0').count
    
    @filter_shop = params[:shop_id].present? ? Shop.find(params[:shop_id]) : nil
    @filter_status = params[:status]
  end

  def show
    # Individual inventory item details
  end
  
  def new
    @shop_inventory = ShopInventory.new
    @shops = current_user.business.shops
    @products = current_user.business.products
  end
  
  def create
    @shop_inventory = ShopInventory.new(shop_inventory_params)
    @shop_inventory.business = current_user.business
    
    if @shop_inventory.save
      redirect_to inventory_index_path, notice: 'Stock added successfully.'
    else
      @shops = current_user.business.shops
      @products = current_user.business.products
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    # Allow editing inventory
  end
  
  def update
    if @inventory.update(inventory_params)
      redirect_to inventory_path(@inventory), 
        notice: 'Inventory updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def restock
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
    @product = current_user.business.products.find(params[:product_id])
    @shops = current_user.business.shops.active
    @current_allocations = @product.shop_inventories.includes(:shop)
    
    if request.post?
      success = true
      total_to_assign = 0
      
      # Calculate total quantity to assign
      params[:allocations].each do |shop_id, allocation_data|
        quantity = allocation_data[:quantity].to_i
        next if quantity <= 0
        
        current_allocation = @current_allocations.find { |a| a.shop_id == shop_id.to_i }
        current_quantity = current_allocation&.quantity || 0
        additional_needed = quantity - current_quantity
        
        total_to_assign += additional_needed if additional_needed > 0
      end
      
      # Check if we have enough business inventory
      if total_to_assign > @product.unassigned_inventory
        flash.now[:alert] = "Cannot assign #{total_to_assign} units. Only #{@product.unassigned_inventory} units available in business inventory."
        render :distribute, status: :unprocessable_entity
        return
      end
      
      ActiveRecord::Base.transaction do
        params[:allocations].each do |shop_id, allocation_data|
          quantity = allocation_data[:quantity].to_i
          next if quantity < 0
          
          shop = current_user.business.shops.find(shop_id)
          inventory = @product.shop_inventories.find_or_initialize_by(shop: shop, business: current_user.business)
          
          current_quantity = inventory.quantity || 0
          
          if quantity > current_quantity
            # Need to assign more from business inventory
            additional_needed = quantity - current_quantity
            if @product.unassigned_inventory >= additional_needed
              @product.update!(business_inventory_quantity: @product.business_inventory_quantity - additional_needed)
              inventory.quantity = quantity
            else
              success = false
              raise ActiveRecord::Rollback
            end
          elsif quantity < current_quantity
            # Return excess to business inventory
            excess = current_quantity - quantity
            @product.update!(business_inventory_quantity: @product.business_inventory_quantity + excess)
            inventory.quantity = quantity
          end
          
          # Set other attributes
          inventory.assign_attributes(
            min_stock_level: allocation_data[:min_stock_level].to_i || @product.min_stock_level,
            max_stock_level: allocation_data[:max_stock_level].to_i || @product.max_stock_level,
            reorder_point: allocation_data[:reorder_point].to_i || @product.reorder_point,
            business: current_user.business
          )
          
          if quantity > 0
            inventory.save!
          elsif inventory.persisted?
            # If quantity is 0 and record exists, delete it
            inventory.destroy!
          end
        end
      end
      
      if success
        redirect_to inventory_index_path, 
          notice: "Inventory distributed successfully for #{@product.name}"
      else
        flash.now[:alert] = "Failed to distribute inventory. Please check quantities."
        render :distribute, status: :unprocessable_entity
      end
    end
  end
  
  def transfer_stock
    # New method to handle stock transfers between shops
    @from_shop = current_user.business.shops.find(params[:from_shop_id]) if params[:from_shop_id].present?
    @to_shop = current_user.business.shops.find(params[:to_shop_id]) if params[:to_shop_id].present?
    @product = current_user.business.products.find(params[:product_id]) if params[:product_id].present?
    
    @shops = current_user.business.shops
    @products = current_user.business.products.joins(:shop_inventories).distinct
    
    if request.post? && @from_shop && @to_shop && @product
      quantity = params[:quantity].to_i
      
      from_inventory = @product.shop_inventories.find_by(shop: @from_shop)
      
      if from_inventory && from_inventory.can_fulfill_quantity?(quantity)
        ActiveRecord::Base.transaction do
          # Remove from source
          from_inventory.update!(quantity: from_inventory.quantity - quantity)
          
          # Add to destination
          to_inventory = @product.shop_inventories.find_or_initialize_by(
            shop: @to_shop,
            product: @product,
            business: current_user.business
          )
          
          if to_inventory.persisted?
            to_inventory.update!(quantity: to_inventory.quantity + quantity)
          else
            to_inventory.assign_attributes(
              quantity: quantity,
              min_stock_level: @product.min_stock_level,
              max_stock_level: @product.max_stock_level,
              reorder_point: @product.reorder_point
            )
            to_inventory.save!
          end
        end
        
        redirect_to inventory_index_path, 
          notice: "Successfully transferred #{quantity} #{@product.unit}(s) from #{@from_shop.name} to #{@to_shop.name}"
      else
        flash.now[:alert] = 'Insufficient stock or invalid transfer details'
        render :transfer_stock
      end
    end
  end
  
  def low_stock
    # Business admin sees low stock across all shops
    @low_stock_items = current_user.business.shop_inventories
                              .includes(:product, :shop)
                              .where('shop_inventories.quantity <= shop_inventories.min_stock_level')
                              .order(:quantity)
    
    @critical_stock = @low_stock_items.where('quantity = 0')
    @warning_stock = @low_stock_items.where('shop_inventories.quantity > 0 AND shop_inventories.quantity <= shop_inventories.min_stock_level')
  end
  
  def stock_report
    # Date filters
    @start_date = params[:start_date]&.to_date || 30.days.ago
    @end_date = params[:end_date]&.to_date || Date.current
    
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
    
    respond_to do |format|
      format.html
      format.csv { 
        send_data generate_stock_report_csv, 
        filename: "stock_report_#{@start_date}_to_#{@end_date}.csv"
      }
    end
  end
  
  def valuation_report
    @shops = current_user.business.shops.includes(shop_inventories: :product)
    
    @shop_valuations = @shops.map do |shop|
      {
        shop: shop,
        total_items: shop.shop_inventories.sum(:quantity),
        total_value: shop.shop_inventories.joins(:product)
                        .sum('quantity * products.selling_price'),
        cost_value: shop.shop_inventories.joins(:product)
                       .sum('quantity * products.buying_price'),
        products_count: shop.shop_inventories.count
      }
    end
    
    @total_business_value = @shop_valuations.sum { |sv| sv[:total_value] }
    @total_business_cost = @shop_valuations.sum { |sv| sv[:cost_value] }
    @total_items = @shop_valuations.sum { |sv| sv[:total_items] }
  end
  
  def movement_history
    @product = current_user.business.products.find(params[:product_id]) if params[:product_id].present?
    @shop = current_user.business.shops.find(params[:shop_id]) if params[:shop_id].present?
    
    # Base query for stock movements
    movements = StockTransfer.where(business: current_user.business)
    
    # Filter by product if specified
    movements = movements.where(product: @product) if @product
    
    # Filter by shop involvement
    movements = movements.where("from_shop_id = ? OR to_shop_id = ?", @shop.id, @shop.id) if @shop
    
    @movements = movements.includes(:product, :from_shop, :to_shop, :initiated_by, :approved_by)
                         .order(created_at: :desc)
                         .paginate(page: params[:page], per_page: 25)
    
    # Available filters for dropdowns
    @available_products = current_user.business.products
    @available_shops = current_user.business.shops
  end
  
  def export_csv
    filename = "business_inventory_#{Date.current}.csv"
    send_data generate_inventory_csv, filename: filename
  end
  
  private
  
  def set_inventory
    @inventory = current_user.business.shop_inventories.find(params[:id])
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
  
  def ensure_business_owner
    unless current_user.business_owner?
      redirect_to dashboard_index_path, alert: 'Access denied. Only business owners can manage inventory.'
    end
  end
  
  def generate_inventory_csv
    require 'csv'
    
    CSV.generate(headers: true) do |csv|
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
          inventory.product.buying_price,
          inventory.product.selling_price,
          inventory.quantity * inventory.product.selling_price
        ]
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

  def shop_inventory_params
    params.require(:shop_inventory).permit(:shop_id, :product_id, :quantity, :min_stock_level, :max_stock_level, :reorder_point)
  end

  def apply_search_filters(inventories)
    if params[:search].present?
      inventories = inventories.where("products.name ILIKE ? OR products.sku ILIKE ?", 
                                     "%#{params[:search]}%", "%#{params[:search]}%")
    end
    
    if params[:shop_id].present?
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

  def apply_product_search_filters(products)
    if params[:search].present?
      products = products.where("products.name ILIKE ? OR products.sku ILIKE ?", 
                                 "%#{params[:search]}%", "%#{params[:search]}%")
    end
    
    if params[:shop_id].present?
      products = products.joins(:shop_inventories).where(shop_inventories: { shop_id: params[:shop_id] })
    end
    
    if params[:status].present?
      case params[:status]
      when 'low_stock'
        products = products.joins(:shop_inventories).where('shop_inventories.quantity <= shop_inventories.min_stock_level')
      when 'out_of_stock'
        products = products.joins(:shop_inventories).where('shop_inventories.quantity = 0')
      when 'overstocked'
        products = products.joins(:shop_inventories).where('shop_inventories.quantity > shop_inventories.max_stock_level')
      end
    end
    
    products.order('products.name ASC')
  end

  def calculate_total_inventory_value
    current_user.business.shop_inventories
                .joins(:product)
                .sum('quantity * products.selling_price')
  end
end
