ActiveAdmin.register User do
  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  
  permit_params :name, :email, :password, :password_confirmation, :role, :shop_id
  
  index do
    selectable_column
    id_column
    column :name
    column :email
    column :shop
    column :role
    column :created_at
    actions
  end

  filter :name
  filter :email
  filter :shop
  filter :role, as: :select, collection: User.roles
  filter :created_at

  form do |f|
    f.inputs do
      f.input :name
      f.input :email
      f.input :shop, as: :select, collection: Shop.all.collect{ |s| [s.name, s.id] }
      f.input :role, as: :select, collection: User.roles.keys.map{ |role| [role.humanize, role] }
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end

  show do
    attributes_table do
      row :name
      row :email
      row :shop
      row :role
      row :created_at
      row :updated_at
    end

    panel "Products Created" do
      table_for user.products.limit(10) do
        column :name
        column :category
        column :quantity
        column :buying_price
        column :selling_price
        column :created_at
      end
    end

    panel "Sales Made" do
      table_for user.sales.limit(10) do
        column :product
        column :quantity
        column :unit_price
        column :total_amount
        column :sale_date
      end
    end
  end
end
