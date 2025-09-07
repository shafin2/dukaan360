module ApplicationHelper
  # FontAwesome icon helper
  def icon(style, name, options = {})
    css_class = "#{style} fa-#{name}"
    css_class += " #{options[:class]}" if options[:class]
    
    content_tag :i, '', class: css_class, **options.except(:class)
  end
end
