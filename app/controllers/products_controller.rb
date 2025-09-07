class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_business_access
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  layout 'dashboard'
  
  def index
    if current_user.business_admin?
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
    unless current_user.can?('create_products')
      redirect_to products_path, alert: 'You do not have permission to create products.'
      return
    end
    
    @product = current_user.business.products.build
    @shops = current_user.business.shops.active
  end
  
  def create
    unless current_user.can?('create_products')
      redirect_to products_path, alert: 'You do not have permission to create products.'
      return
    end
    
    @product = current_user.business.products.build(product_params)
    @product.created_by_id = current_user.id
    
    if @product.save
      # If shop allocations are provided, create shop inventories
      if params[:shop_allocations].present?
        params[:shop_allocations].each do |shop_id, allocation_data|
          next if allocation_data[:quantity].blank? || allocation_data[:quantity].to_i.zero?
          
          ShopInventory.create!(
            product: @product,
            shop: current_user.business.shops.find(shop_id),
            business: current_user.business,
            quantity: allocation_data[:quantity].to_i,
            min_stock_level: allocation_data[:min_stock_level].to_i || @product.min_stock_level,
            max_stock_level: allocation_data[:max_stock_level].to_i || @product.max_stock_level,
            reorder_point: allocation_data[:reorder_point].to_i || @product.reorder_point
          )
        end
      end
      
      redirect_to products_path, 
        notice: 'Product was successfully created and allocated to shops.'
    else
      @shops = current_user.business.shops.active
      render :new, status: :unprocessable_entity
    end
  end
  
  def show
    # Product details with shop inventory information
    if current_user.business_admin?
      @shop_inventories = @product.shop_inventories.includes(:shop)
    else
      @shop_inventories = @product.shop_inventories.where(shop: current_user.shop)
    end
    @recent_transfers = @product.stock_transfers.recent.limit(5).includes(:from_shop, :to_shop, :initiated_by)
  end
  
  def edit
    unless current_user.can?('edit_products')
      redirect_to product_path(@product), alert: 'You do not have permission to edit products.'
      return
    end
    
    @shops = current_user.business.shops.active
    @shop_inventories = @product.shop_inventories.includes(:shop)
  end
  
  def update
    unless current_user.can?('edit_products')
      redirect_to product_path(@product), alert: 'You do not have permission to edit products.'
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
    @product.destroy
    redirect_to products_path, 
      notice: t('products.messages.deleted_successfully')
  end
  
  private
  
  def set_product
    if current_user.business_admin?
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
