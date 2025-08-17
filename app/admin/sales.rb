ActiveAdmin.register Sale do
  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  
  permit_params :product_id, :user_id, :quantity, :unit_price, :total_amount, :sale_date
  
  index do
    selectable_column
    id_column
    column :product
    column :user
    column :quantity
    column :unit_price
    column :total_amount
    column :sale_date
    column :created_at
    actions
  end

  filter :product
  filter :user
  filter :sale_date
  filter :created_at

  form do |f|
    f.inputs do
      f.input :product, as: :select, collection: Product.all.collect{ |p| ["#{p.name} (#{p.shop.name})", p.id] }
      f.input :user, as: :select, collection: User.all.collect{ |u| ["#{u.name} (#{u.shop.name})", u.id] }
      f.input :quantity
      f.input :unit_price
      f.input :total_amount
      f.input :sale_date, as: :datetime_picker
    end
    f.actions
  end

  show do
    attributes_table do
      row :product do |sale|
        "#{sale.product.name} (#{sale.product.shop.name})"
      end
      row :user do |sale|
        "#{sale.user.name} (#{sale.user.shop.name})"
      end
      row :quantity
      row :unit_price
      row :total_amount
      row :sale_date
      row :created_at
      row :updated_at
    end
  end
end
