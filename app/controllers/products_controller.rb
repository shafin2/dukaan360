class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_shop_access
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  layout 'dashboard'
  
  def index
    @products = current_user.shop.products
                           .includes(:user)
                           .search_by_params(search_params)
                           .paginate(page: params[:page], per_page: 20)
    @categories = current_user.shop.products.distinct.pluck(:category).compact
  end
  
  def show
    # Product details view
  end
  
  def new
    @product = current_user.shop.products.build
  end
  
  def create
    @product = current_user.shop.products.build(product_params)
    @product.created_by_id = current_user.id
    
    if @product.save
      redirect_to products_path, 
        notice: t('products.messages.created_successfully')
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    # Edit form
  end
  
  def update
    if @product.update(product_params)
      redirect_to product_path(@product), 
        notice: t('products.messages.updated_successfully')
    else
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
    @product = current_user.shop.products.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to products_path, alert: t('products.messages.not_found')
  end
  
  def product_params
    params.require(:product).permit(
      :name, :buying_price, :selling_price, 
      :quantity, :expiry_date, :image_url
    )
  end
  
  def search_params
    params.permit(:search, :category, :sort_by, :sort_direction)
  end
  
  def ensure_shop_access
    unless current_user.shop.present?
      redirect_to root_path, alert: t('common.access_denied')
    end
  end
end
