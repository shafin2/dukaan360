ActiveAdmin.register Business do
  menu priority: 1
  
  permit_params :name, :description, :business_type, :contact_email, :contact_phone, 
                :address, :logo_url, :primary_color, :secondary_color, :website_url, 
                :active, settings: {}

  index do
    selectable_column
    id_column
    column :name
    column :business_type
    column :contact_email
    column :contact_phone
    column :active
    column "Shops" do |business|
      business.shops.count
    end
    column "Users" do |business|
      business.users.count
    end
    column :created_at
    actions
  end

  filter :name
  filter :business_type
  filter :contact_email
  filter :active
  filter :created_at

  show do
    attributes_table do
      row :name
      row :description
      row :business_type
      row :contact_email
      row :contact_phone
      row :address
      row :logo_url do |business|
        if business.logo_url.present?
          image_tag business.logo_url, style: "max-width: 100px; max-height: 100px;"
        else
          "No logo"
        end
      end
      row :primary_color do |business|
        content_tag :div, business.primary_color, style: "background-color: #{business.primary_color}; padding: 10px; color: white; border-radius: 4px;"
      end
      row :secondary_color do |business|
        content_tag :div, business.secondary_color, style: "background-color: #{business.secondary_color}; padding: 10px; color: white; border-radius: 4px;"
      end
      row :website_url
      row :active
      row :settings
      row :created_at
      row :updated_at
    end

    panel "Shops (#{business.shops.count})" do
      table_for business.shops do
        column :name
        column :address
        column "Users" do |shop|
          shop.users.count
        end
        column "Products" do |shop|
          shop.products.count
        end
        column :created_at
      end
    end

    panel "Users (#{business.users.count})" do
      table_for business.users do
        column :name
        column :email
        column :role
        column :shop
        column :created_at
      end
    end
  end

  form do |f|
    f.inputs "Business Information" do
      f.input :name
      f.input :description
      f.input :business_type, as: :select, collection: ['Retail', 'Wholesale', 'Restaurant', 'Pharmacy', 'Electronics', 'Clothing', 'Grocery', 'Other']
      f.input :contact_email
      f.input :contact_phone
      f.input :address, as: :text
    end

    f.inputs "Branding" do
      f.input :logo_url, label: "Logo URL"
      f.input :primary_color, as: :color
      f.input :secondary_color, as: :color
      f.input :website_url
    end

    f.inputs "Status" do
      f.input :active
    end

    f.actions
  end
end
