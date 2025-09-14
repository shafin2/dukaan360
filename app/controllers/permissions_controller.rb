class PermissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_business_owner
  
  def index
    # Simple role-based system - redirect to users management
    redirect_to users_path, notice: 'User roles are managed through the Users section.'
  end
  
  private
  
  def ensure_business_owner
    unless current_user.business_owner?
      redirect_to root_path, alert: 'Access denied. Only business owners can manage permissions.'
    end
  end
end
