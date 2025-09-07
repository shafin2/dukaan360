ActiveAdmin.register Shop do
  menu priority: 2
  
  permit_params :name, :address, :business_id, settings: {}
  
  index do
    selectable_column
    id_column
    column :name
    column :business
    column :address
    column :users_count do |shop|
      shop.users.count
    end
    column "Inventory Items" do |shop|
      shop.shop_inventories.count
    end
    column :created_at
    actions
  end

  filter :name
  filter :business
  filter :created_at

  form do |f|
    f.inputs "Shop Information" do
      f.input :business, as: :select, collection: Business.active.collect{ |b| [b.name, b.id] }, include_blank: "Select Business"
      f.input :name
      f.input :address, as: :text
    end
    f.actions
  end

  show do
    attributes_table do
      row :name
      row :business
      row :address
      row :settings do |shop|
        shop.settings.present? ? JSON.pretty_generate(shop.settings) : "No settings"
      end
      row :created_at
      row :updated_at
    end

    panel "Users (#{shop.users.count})" do
      table_for shop.users do
        column :name
        column :email
        column :role
        column :created_at
      end
    end

    panel "Inventory (#{shop.shop_inventories.count})" do
      table_for shop.shop_inventories.includes(:product).limit(10) do
        column :product
        column :quantity
        column :low_stock_threshold
        column :created_at
      end
    end
  end
end
