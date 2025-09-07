# Prevent conflicts between will_paginate and kaminari
# ActiveAdmin uses Kaminari, regular app uses will_paginate

if defined?(WillPaginate)
  module WillPaginate
    module ActiveRecord
      module RelationMethods
        def per(value = nil)
          if value
            limit(value)
          else
            limit_value
          end
        end
        
        def padding(value)
          offset(value)
        end
      end
    end
  end
end

# Configure Kaminari to not interfere with will_paginate
if defined?(Kaminari)
  Kaminari.configure do |config|
    config.page_method_name = :page
  end
end
