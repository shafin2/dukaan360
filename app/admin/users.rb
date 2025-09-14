ActiveAdmin.register User do
  menu priority: 4
  
  permit_params :name, :email, :password, :password_confirmation, :role, :shop_id, :business_id
  
  controller do
    def scoped_collection
      super.page(params[:page]).per(30)
    end
  end
  
  index do
    selectable_column
    id_column
    column :name
    column :email
    column :business
    column :shop
    column :role do |user|
      status_tag user.role.humanize
    end
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
      f.input :business, as: :select, collection: Business.all.collect{ |b| [b.name, b.id] }, include_blank: "Select Business"
      f.input :shop, as: :select, collection: Shop.all.collect{ |s| ["#{s.business.name} - #{s.name}", s.id] }, include_blank: "Select Shop (Only for shop workers)"
      f.input :password, hint: "Leave blank to keep current password"
      f.input :password_confirmation
    end
    f.actions
  end
end
