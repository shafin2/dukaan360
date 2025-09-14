module UserHelper
  # Helper methods to make role checking cleaner in views
  
  def current_user_is_business_owner?
    current_user&.business_owner?
  end
  
  def current_user_is_shop_worker?
    current_user&.shop_worker?
  end
  
  def current_user_business_name
    current_user&.business&.name
  end
  
  def current_user_shop_name
    current_user&.shop&.name
  end
  
  # Display friendly role name
  def display_role(user)
    case user.role
    when 'business_owner'
      'Business Owner'
    when 'shop_worker'
      'Shop Worker'
    else
      user.role.humanize
    end
  end
end
