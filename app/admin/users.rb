ActiveAdmin.register User do
  menu priority: 3
  
  permit_params :name, :email, :password, :password_confirmation, :role, :shop_id, :business_id
  
  index do
    selectable_column
    id_column
    column :name
    column :email
    column :business
    column :shop
    column :role
    column :created_at
    actions
  end

  filter :name
  filter :email
  filter :business
  filter :shop
  filter :role, as: :select, collection: User.roles
  filter :created_at

  form do |f|
    f.inputs "User Information" do
      f.input :name
      f.input :email
      f.input :role, as: :select, collection: User.roles.keys.map{ |role| [role.humanize, role] }
      f.input :business, as: :select, collection: Business.active.collect{ |b| [b.name, b.id] }, include_blank: "Select Business (Required for business_admin and worker)"
      f.input :shop, as: :select, collection: Shop.joins(:business).where(businesses: { active: true }).collect{ |s| ["#{s.business.name} - #{s.name}", s.id] }, include_blank: "Select Shop (Required for workers only)"
      f.input :password, hint: "Leave blank to keep current password"
      f.input :password_confirmation
    end
    f.actions
  end

  show do
    attributes_table do
      row :name
      row :email
      row :business
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
