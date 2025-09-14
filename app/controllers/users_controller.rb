class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_business_owner
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  layout 'dashboard'
  
  def index
    @users = current_user.business.users
                         .where.not(role: :business_owner)
                         .includes(:shop)
                         .order(:name)
    @shops = current_user.business.shops
    @pending_users = @users.where(shop: nil)
  end
  
  def show
  end
  
  def new
    @user = current_user.business.users.build
    @shops = current_user.business.shops
  end
  
  def create
    @user = current_user.business.users.build(user_params)
    @user.password = 'password123' # Default password
    @user.role = :shop_worker # Default role
    
    if @user.save
      redirect_to users_path, notice: 'Worker created successfully. Default password is "password123"'
    else
      @shops = current_user.business.shops
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    @shops = current_user.business.shops
  end
  
  def update
    if @user.update(user_params)
      redirect_to users_path, notice: 'Worker updated successfully.'
    else
      @shops = current_user.business.shops
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @user.destroy
    redirect_to users_path, notice: 'Worker deleted successfully.'
  end
  
  def assign_shop
    @user = current_user.business.users.find(params[:id])
    shop = current_user.business.shops.find(params[:shop_id])
    
    if @user.update(shop: shop)
      redirect_to users_path, notice: "#{@user.name} assigned to #{shop.name} successfully."
    else
      redirect_to users_path, alert: 'Failed to assign shop.'
    end
  end
  
  def reset_password
    @user = current_user.business.users.find(params[:id])
    new_password = 'password123'
    
    if @user.update(password: new_password)
      redirect_to users_path, notice: "Password reset for #{@user.name}. New password is: #{new_password}"
    else
      redirect_to users_path, alert: 'Failed to reset password.'
    end
  end
  
  private
  
  def set_user
    @user = current_user.business.users.find(params[:id])
  end
  
  def user_params
    params.require(:user).permit(:name, :email, :shop_id, :role)
  end
  
  def ensure_business_owner
    unless current_user.business_owner?
      redirect_to dashboard_index_path, alert: 'Access denied. Only business owners can manage workers.'
    end
  end
end
