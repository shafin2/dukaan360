ActiveAdmin.register UserPermission do
  menu priority: 4, label: "User Permissions"
  
  permit_params :user_id, :permission_id, :shop_id, :granted, :notes

  index do
    selectable_column
    id_column
    column :user do |up|
      link_to up.user.name, admin_user_path(up.user)
    end
    column :permission do |up|
      up.permission.display_name
    end
    column :shop do |up|
      up.shop&.name || 'Global'
    end
    column :granted do |up|
      status_tag(up.granted? ? 'Granted' : 'Revoked', up.granted? ? :ok : :error)
    end
    column :notes, sortable: false
    column :created_at
    actions
  end

  filter :user, as: :select, collection: -> { User.order(:name).pluck(:name, :id) }
  filter :permission, as: :select, collection: -> { Permission.order(:name).pluck(:name, :id) }
  filter :shop, as: :select, collection: -> { Shop.order(:name).pluck(:name, :id) }
  filter :granted
  filter :created_at

  show do
    attributes_table do
      row :user do |up|
        link_to up.user.name, admin_user_path(up.user)
      end
      row :permission do |up|
        link_to up.permission.display_name, admin_permission_path(up.permission)
      end
      row :shop do |up|
        if up.shop
          link_to up.shop.name, admin_shop_path(up.shop)
        else
          'Global Permission'
        end
      end
      row :granted do |up|
        status_tag(up.granted? ? 'Granted' : 'Revoked', up.granted? ? :ok : :error)
      end
      row :notes
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs "User Permission Assignment" do
      f.input :user, as: :select, collection: User.order(:name)
      f.input :permission, as: :select, collection: Permission.order(:name)
      f.input :shop, as: :select, collection: Shop.order(:name), include_blank: 'Global Permission'
      f.input :granted, as: :boolean
      f.input :notes, as: :text
    end
    f.actions
  end
end
