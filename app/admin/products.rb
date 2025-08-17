ActiveAdmin.register Product do
  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  
  permit_params :name, :category, :buying_price, :selling_price, :quantity, :expiry_date, :shop_id, :created_by_id
  
  index do
    selectable_column
    id_column
    column :name
    column :category
    column :shop
    column :quantity
    column :buying_price
    column :selling_price
    column :expiry_date
    column :created_at
    actions
  end

  filter :name
  filter :category
  filter :shop
  filter :expiry_date
  filter :created_at

  form do |f|
    f.inputs do
      f.input :name
      f.input :category
      f.input :shop, as: :select, collection: Shop.all.collect{ |s| [s.name, s.id] }
      f.input :buying_price
      f.input :selling_price
      f.input :quantity
      f.input :expiry_date, as: :date_picker
      f.input :created_by_id, as: :select, collection: User.all.collect{ |u| [u.name, u.id] }, label: "Created By"
    end
    f.actions
  end

  show do
    attributes_table do
      row :name
      row :category
      row :shop
      row :buying_price
      row :selling_price
      row :quantity
      row :expiry_date
      row :created_by_id do |product|
        User.find(product.created_by_id).name
      end
      row :created_at
      row :updated_at
    end

    panel "Sales History" do
      table_for product.sales do
        column :user
        column :quantity
        column :unit_price
        column :total_amount
        column :sale_date
      end
    end
  end
end
