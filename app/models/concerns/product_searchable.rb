module ProductSearchable
  extend ActiveSupport::Concern
  
  class_methods do
    def search_by_params(params)
      scope = all
      
      if params[:search].present?
        scope = scope.search_by_name_or_category(params[:search])
      end
      
      if params[:category].present?
        scope = scope.where(category: params[:category])
      end
      
      scope = apply_sorting(scope, params[:sort_by], params[:sort_direction])
      scope
    end
    
    def search_by_name_or_category(term)
      where("name ILIKE ? OR category ILIKE ?", "%#{term}%", "%#{term}%")
    end
    
    def low_stock(threshold = 10)
      where('quantity <= ?', threshold)
    end
    
    def expiring_soon(days = 30)
      where('expiry_date <= ?', Date.current + days.days)
        .where('expiry_date > ?', Date.current)
    end
    
    def expired
      where('expiry_date < ?', Date.current)
    end
    
    private
    
    def apply_sorting(scope, sort_by, sort_direction)
      return scope.order(created_at: :desc) unless sort_by.present?
      
      direction = sort_direction == 'desc' ? :desc : :asc
      
      case sort_by
      when 'name'
        scope.order(name: direction)
      when 'category'
        scope.order(category: direction, name: :asc)
      when 'price'
        scope.order(selling_price: direction)
      when 'quantity'
        scope.order(quantity: direction)
      when 'expiry_date'
        scope.order(expiry_date: direction)
      else
        scope.order(created_at: :desc)
      end
    end
  end
end
