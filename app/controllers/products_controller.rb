class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_business_access
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  layout 'dashboard'
  
  def index
    if current_user.business_owner?
      # Business admin sees all products in their business
      @products = current_user.business.products
                             .includes(:user, :shop_inventories => :shop)
                             .search_by_params(search_params)
                             .paginate(page: params[:page], per_page: 20)
    else
      # Workers see only products available in their shop
      @products = current_user.business.products
                             .joins(:shop_inventories)
                             .where(shop_inventories: { shop: current_user.shop })
                             .includes(:user, :shop_inventories => :shop)
                             .search_by_params(search_params)
                             .paginate(page: params[:page], per_page: 20)
    end
    
    @categories = current_user.business.products.distinct.pluck(:category).compact
    @current_shop = current_user.shop
  end
  
  def show
    # Product details view
  end
  
  def new
    unless current_user.business_owner?
      redirect_to products_path, alert: 'Only business owners can create products.'
      return
    end
    
    @product = current_user.business.products.build
    @shops = current_user.business.shops.active
  end
  
  def create
    unless current_user.business_owner?
      redirect_to products_path, alert: 'Only business owners can create products.'
      return
    end
    
    @product = current_user.business.products.build(product_params.except(:quantity, :shop_id))
    @product.created_by_id = current_user.id
    
    # Set business inventory quantity from the form
    initial_quantity = params[:product][:quantity].to_i
    @product.business_inventory_quantity = initial_quantity
    
    if @product.save
      shop_id = params[:product][:shop_id]
      
      # If shop is selected, assign the inventory to that shop
      if initial_quantity > 0 && shop_id.present?
        shop = current_user.business.shops.find(shop_id)
        if @product.assign_to_shop(shop, initial_quantity, current_user)
          redirect_to products_path, 
            notice: "Product created successfully with #{initial_quantity} units assigned to #{shop.name}."
        else
          redirect_to products_path, 
            alert: "Product created but failed to assign to shop. Stock remains in business inventory."
        end
      else
        # Stock stays in business inventory
        redirect_to products_path, 
          notice: "Product created successfully with #{initial_quantity} units in business inventory. You can assign to shops later."
      end
    else
      @shops = current_user.business.shops.active
      render :new, status: :unprocessable_entity
    end
  end
  
  def show
    # Product details with shop inventory information
    if current_user.business_owner?
      @shop_inventories = @product.shop_inventories.includes(:shop)
    else
      @shop_inventories = @product.shop_inventories.where(shop: current_user.shop)
    end
    @recent_transfers = @product.stock_transfers.recent.limit(5).includes(:from_shop, :to_shop, :initiated_by)
  end
  
  def edit
    unless current_user.business_owner?
      redirect_to product_path(@product), alert: 'Only business owners can edit products.'
      return
    end
    
    @shops = current_user.business.shops.active
    @shop_inventories = @product.shop_inventories.includes(:shop)
  end
  
  def update
    unless current_user.business_owner?
      redirect_to product_path(@product), alert: 'Only business owners can edit products.'
      return
    end
    
    if @product.update(product_params)
      # Update shop inventory allocations if provided
      if params[:shop_allocations].present?
        params[:shop_allocations].each do |shop_id, allocation_data|
          inventory = @product.shop_inventories.find_or_initialize_by(
            shop: current_user.business.shops.find(shop_id)
          )
          
          if allocation_data[:quantity].present?
            inventory.assign_attributes(
              quantity: allocation_data[:quantity].to_i,
              min_stock_level: allocation_data[:min_stock_level].to_i || @product.min_stock_level,
              max_stock_level: allocation_data[:max_stock_level].to_i || @product.max_stock_level,
              reorder_point: allocation_data[:reorder_point].to_i || @product.reorder_point,
              business: current_user.business
            )
            inventory.save!
          end
        end
      end
      
      redirect_to product_path(@product), 
        notice: 'Product was successfully updated.'
    else
      @shops = current_user.business.shops.active
      @shop_inventories = @product.shop_inventories.includes(:shop)
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    unless current_user.business_owner?
      redirect_to products_path, alert: 'Only business owners can delete products.'
      return
    end
    
    @product.destroy
    redirect_to products_path, 
      notice: 'Product was successfully deleted.'
  end
  
  def add_stock
    @product = current_user.business.products.find(params[:id])
    
    unless current_user.business_owner?
      redirect_to products_path, alert: 'Access denied.'
      return
    end
    
    if params[:restock_quantity].present? && params[:restock_quantity].to_i > 0
      quantity = params[:restock_quantity].to_i
      
      @product.update!(
        business_inventory_quantity: @product.business_inventory_quantity + quantity
      )
      
      redirect_to inventory_index_path,
        notice: "Successfully added #{quantity} #{@product.unit}(s) to business inventory. New total: #{@product.business_inventory_quantity}"
    else
      redirect_to inventory_index_path,
        alert: 'Please enter a valid quantity.'
    end
  end

  def assign_stock
    @product = current_user.business.products.find(params[:id])
    
    unless current_user.business_owner?
      redirect_to inventory_index_path, alert: 'Access denied.'
      return
    end
    
    shop_id = params[:assign_shop_id]
    quantity = params[:assign_quantity].to_i
    
    if shop_id.blank? || quantity <= 0
      redirect_to inventory_index_path, alert: 'Please select a shop and enter a valid quantity.'
      return
    end
    
    if quantity > @product.unassigned_inventory
      redirect_to inventory_index_path, alert: "Cannot assign #{quantity} units. Only #{@product.unassigned_inventory} units available in business inventory."
      return
    end
    
    shop = current_user.business.shops.find(shop_id)
    
    ActiveRecord::Base.transaction do
      # Reduce business inventory
      @product.update!(
        business_inventory_quantity: @product.business_inventory_quantity - quantity
      )
      
      # Add to shop inventory
      shop_inventory = @product.shop_inventories.find_or_initialize_by(
        shop: shop, 
        business: current_user.business
      )
      
      if shop_inventory.persisted?
        shop_inventory.update!(quantity: shop_inventory.quantity + quantity)
      else
        shop_inventory.assign_attributes(
          quantity: quantity,
          min_stock_level: @product.min_stock_level,
          max_stock_level: @product.max_stock_level,
          reorder_point: @product.reorder_point
        )
        shop_inventory.save!
      end
    end
    
    redirect_to inventory_index_path,
      notice: "Successfully assigned #{quantity} #{@product.unit}(s) of '#{@product.name}' to #{shop.name}"
  rescue ActiveRecord::RecordNotFound
    redirect_to inventory_index_path, alert: 'Shop not found.'
  end

  private
  
  def set_product
    if current_user.business_owner?
      @product = current_user.business.products.find(params[:id])
    else
      # Workers can only view products available in their shop
      @product = current_user.business.products
                             .joins(:shop_inventories)
                             .where(shop_inventories: { shop: current_user.shop })
                             .find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to products_path, alert: 'Product not found or access denied.'
  end
  
  def product_params
    params.require(:product).permit(
      :name, :buying_price, :selling_price, :category, :sku, :description,
      :expiry_date, :image_url, :min_stock_level, :max_stock_level, 
      :reorder_point, :unit
    )
  end
  
  def search_params
    params.permit(:search, :category, :sort_by, :sort_direction)
  end
  
  def ensure_business_access
    unless current_user.business.present?
      redirect_to root_path, alert: 'Access denied. Please contact administrator.'
    end
  end
end
