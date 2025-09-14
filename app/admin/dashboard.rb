# frozen_string_literal: true
ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    div class: "blank_slate_container", id: "dashboard_default_message" do
      span class: "blank_slate" do
        span "Dukaan360 Admin Panel"
        small "Simple admin interface for managing the system"
      end
    end

    div do
      h3 "System Statistics"
      
      div style: "display: flex; gap: 20px; margin: 20px 0;" do
        div style: "background: #f8f9fa; padding: 15px; border-radius: 5px;" do
          strong "Total Businesses: #{Business.count}"
        end
        
        div style: "background: #f8f9fa; padding: 15px; border-radius: 5px;" do
          strong "Total Shops: #{Shop.count}"
        end
        
        div style: "background: #f8f9fa; padding: 15px; border-radius: 5px;" do
          strong "Total Users: #{User.count}"
        end
      end
    end

    div do
      h4 "Recent Businesses"
      table do
        thead do
          tr do
            th "Name"
            th "Created"
            th "Shops"
            th "Users"
          end
        end
        tbody do
          Business.order(created_at: :desc).limit(5).each do |business|
            tr do
              td link_to(business.name, admin_business_path(business))
              td business.created_at.strftime("%b %d, %Y")
              td business.shops.count
              td business.users.count
            end
          end
        end
      end
    end

    div do
      h4 "Recent Users"
      table do
        thead do
          tr do
            th "Name"
            th "Email"
            th "Role"
            th "Business"
          end
        end
        tbody do
          User.order(created_at: :desc).limit(5).each do |user|
            tr do
              td link_to(user.name, admin_user_path(user))
              td user.email
              td user.role.humanize
              td user.business&.name || "No Business"
            end
          end
        end
      end
    end
  end
end
