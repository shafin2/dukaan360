ActiveAdmin.register Permission do
  menu priority: 3
  
  permit_params :name, :resource, :action, :description, :category, :system_permission

  index do
    selectable_column
    id_column
    column :name
    column :resource
    column :action
    column :category do |permission|
      status_tag permission.category, class: permission.category
    end
    column :description, sortable: false
    column "Users Assigned" do |permission|
      permission.users.count
    end
    column :system_permission
    column :created_at
    actions
  end

  filter :name
  filter :resource
  filter :action
  filter :category, as: :select, collection: Permission::CATEGORIES
  filter :system_permission
  filter :created_at

  show do
    attributes_table do
      row :name
      row :resource
      row :action
      row :category do |permission|
        status_tag permission.category, class: permission.category
      end
      row :description
      row :system_permission
      row :created_at
      row :updated_at
    end

    panel "Assigned Users (#{permission.users.count})" do
      if permission.users.any?
        table_for permission.user_permissions.includes(:user, :shop) do
          column :user do |up|
            link_to up.user.name, admin_user_path(up.user)
          end
          column :shop do |up|
            up.shop&.name || 'Global'
          end
          column :granted do |up|
            status_tag(up.granted? ? 'Granted' : 'Revoked', up.granted? ? :ok : :error)
          end
          column :created_at
        end
      else
        div "No users assigned to this permission"
      end
    end
  end

  form do |f|
    f.inputs "Permission Details" do
      f.input :name, hint: "Unique permission name (e.g., 'view_sales')"
      f.input :resource, hint: "Resource this permission applies to (e.g., 'sales')"
      f.input :action, hint: "Action allowed on resource (e.g., 'view')"
      f.input :category, as: :select, collection: Permission::CATEGORIES
      f.input :description, as: :text
      f.input :system_permission, hint: "System permissions are reserved for super admins"
    end
    f.actions
  end
end
