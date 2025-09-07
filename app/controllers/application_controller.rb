class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  # Don't authenticate admin routes - they have their own authentication
  before_action :authenticate_user!, unless: :admin_controller?
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_locale
  
  # Redirect after sign in
  def after_sign_in_path_for(resource)
    if resource.is_a?(User)
      case resource.role
      when 'super_admin'
        admin_root_path  # Redirect to ActiveAdmin
      when 'business_admin', 'worker'
        dashboard_index_path  # Redirect to website dashboard
      else
        dashboard_index_path
      end
    else
      super
    end
  end
  
  private
  
  def admin_controller?
    # Check if we're in an admin namespace
    params[:controller] =~ /^admin\//
  end
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :shop_id, :role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end
  
  def set_locale
    I18n.locale = params[:locale] || session[:locale] || I18n.default_locale
    session[:locale] = I18n.locale
  end
end
