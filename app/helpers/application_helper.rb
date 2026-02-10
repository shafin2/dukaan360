module ApplicationHelper
  # FontAwesome icon helper
  def icon(style, name, options = {})
    css_class = "#{style} fa-#{name}"
    css_class += " #{options[:class]}" if options[:class]
    
    content_tag :i, '', class: css_class, **options.except(:class)
  end
  
  # Convert hex color to RGB values for CSS
  def hex_to_rgb(hex_color)
    return "59, 130, 246" unless hex_color # Default blue if no color
    
    # Remove # if present
    hex = hex_color.delete('#')
    
    # Convert to RGB
    if hex.length == 3
      r, g, b = hex.chars.map { |c| (c * 2).to_i(16) }
    else
      r = hex[0..1].to_i(16)
      g = hex[2..3].to_i(16)
      b = hex[4..5].to_i(16)
    end
    
    "#{r}, #{g}, #{b}"
  end
  
  # Nav link helper with brand colors
  def nav_link_active_class
    "brand-text-primary brand-border-primary border-r-2"
  end
  
  def nav_link_inactive_class
    "text-gray-600 hover:text-gray-900 hover:bg-gray-50"
  end
  
  def nav_icon_active_class
    "brand-bg-primary text-white"
  end
  
  def nav_icon_inactive_class
    "bg-gray-100 group-hover:bg-gray-200"
  end
end
