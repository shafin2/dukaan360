ActiveAdmin.register Shop do
  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  
  permit_params :name, :address, settings: {}
  
  index do
    selectable_column
    id_column
    column :name
    column :address
    column :users_count do |shop|
      shop.users.count
    end
    column :products_count do |shop|
      shop.products.count
    end
    column :created_at
    actions
  end

  filter :name
  filter :created_at

  form do |f|
    f.inputs do
      f.input :name
      f.input :address, as: :text
      f.input :settings, as: :jsonb
    end
    f.actions
  end

  show do
    attributes_table do
      row :name
      row :address
      row :settings do |shop|
        shop.settings.present? ? JSON.pretty_generate(shop.settings) : "No settings"
      end
      row :created_at
      row :updated_at
    end

    panel "Users" do
      table_for shop.users do
        column :name
        column :email
        column :role
        column :created_at
      end
    end

    panel "Products" do
      table_for shop.products.limit(10) do
        column :name
        column :category
        column :quantity
        column :buying_price
        column :selling_price
        column :created_at
      end
    end
  end
end
