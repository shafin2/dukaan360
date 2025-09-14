ActiveAdmin.register Business do
  menu priority: 2
  
  permit_params :name, :description, :business_type, :contact_email, :contact_phone, 
                :address, :primary_color, :secondary_color, :active

  controller do
    def scoped_collection
      super.page(params[:page]).per(30)
    end
  end

  index do
    selectable_column
    id_column
    column :name
    column :business_type
    column :contact_email
    column :active do |business|
      status_tag business.active? ? 'Active' : 'Inactive'
    end
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

  form do |f|
    f.inputs "Business Information" do
      f.input :name
      f.input :description
      f.input :business_type, as: :select, collection: ['Retail', 'Wholesale', 'Restaurant', 'Pharmacy', 'Electronics', 'Clothing', 'Grocery', 'Other']
      f.input :contact_email
      f.input :contact_phone
      f.input :address, as: :text
      f.input :primary_color, as: :color, input_html: { value: f.object.primary_color || '#3B82F6' }
      f.input :secondary_color, as: :color, input_html: { value: f.object.secondary_color || '#1E40AF' }
      f.input :active
    end
    f.actions
  end
end
