ActiveAdmin.register Shop do
  menu priority: 3
  
  permit_params :name, :address, :business_id
  
  controller do
    def scoped_collection
      super.page(params[:page]).per(30)
    end
  end
  
  index do
    selectable_column
    id_column
    column :name
    column :business
    column :address
    column "Workers" do |shop|
      shop.shop_workers.count
    end
    column :created_at
    actions
  end

  filter :name
  filter :business
  filter :created_at

  form do |f|
    f.inputs "Shop Information" do
      f.input :business, as: :select, collection: Business.all.collect{ |b| [b.name, b.id] }, include_blank: "Select Business"
      f.input :name
      f.input :address, as: :text
    end
    f.actions
  end
end
