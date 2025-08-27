class HomeController < ApplicationController
  skip_before_action :authenticate_user!
  
  def index
    # Redirect to dashboard if user is already logged in
    redirect_to dashboard_index_path if user_signed_in?
  end
end
