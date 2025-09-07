class CreatePermissionsSeeds < ActiveRecord::Migration[8.0]
  def up
    # Define all permissions with categories
    permissions_data = [
      # Sales permissions
      { name: 'view_sales', resource: 'sales', action: 'view', category: 'sales', 
        description: 'Can view sales records and transactions' },
      { name: 'create_sales', resource: 'sales', action: 'create', category: 'sales',
        description: 'Can create new sales and process transactions' },
      { name: 'edit_sales', resource: 'sales', action: 'edit', category: 'sales',
        description: 'Can edit existing sales records' },
      { name: 'delete_sales', resource: 'sales', action: 'delete', category: 'sales',
        description: 'Can delete sales records' },
      
      # Product/Inventory permissions
      { name: 'view_products', resource: 'products', action: 'view', category: 'inventory',
        description: 'Can view product catalog and inventory' },
      { name: 'create_products', resource: 'products', action: 'create', category: 'inventory',
        description: 'Can add new products to inventory' },
      { name: 'edit_products', resource: 'products', action: 'edit', category: 'inventory',
        description: 'Can edit product details and pricing' },
      { name: 'delete_products', resource: 'products', action: 'delete', category: 'inventory',
        description: 'Can remove products from inventory' },
      { name: 'view_buying_price', resource: 'products', action: 'view_buying_price', category: 'inventory',
        description: 'Can see product buying prices and profit margins' },
      { name: 'manage_inventory', resource: 'inventory', action: 'manage', category: 'inventory',
        description: 'Can manage stock levels and inventory allocation' },
      
      # Customer permissions  
      { name: 'view_customers', resource: 'customers', action: 'view', category: 'customers',
        description: 'Can view customer list and details' },
      { name: 'create_customers', resource: 'customers', action: 'create', category: 'customers',
        description: 'Can add new customers to the system' },
      { name: 'edit_customers', resource: 'customers', action: 'edit', category: 'customers',
        description: 'Can edit customer information' },
      { name: 'delete_customers', resource: 'customers', action: 'delete', category: 'customers',
        description: 'Can remove customers from the system' },
      
      # Billing permissions
      { name: 'view_bills', resource: 'bills', action: 'view', category: 'billing',
        description: 'Can view bills and invoices' },
      { name: 'create_bills', resource: 'bills', action: 'create', category: 'billing',
        description: 'Can create bills and invoices' },
      { name: 'edit_bills', resource: 'bills', action: 'edit', category: 'billing',
        description: 'Can edit existing bills and invoices' },
      { name: 'delete_bills', resource: 'bills', action: 'delete', category: 'billing',
        description: 'Can delete bills and invoices' },
      { name: 'mark_bills_paid', resource: 'bills', action: 'mark_paid', category: 'billing',
        description: 'Can mark bills as paid or update payment status' },
      
      # Payment permissions
      { name: 'view_payments', resource: 'payments', action: 'view', category: 'billing',
        description: 'Can view payment records' },
      { name: 'create_payments', resource: 'payments', action: 'create', category: 'billing',
        description: 'Can record new payments' },
      { name: 'edit_payments', resource: 'payments', action: 'edit', category: 'billing',
        description: 'Can edit payment records' },
      { name: 'delete_payments', resource: 'payments', action: 'delete', category: 'billing',
        description: 'Can delete payment records' },
      
      # Reports permissions
      { name: 'view_reports', resource: 'reports', action: 'view', category: 'reports',
        description: 'Can view business reports and analytics' },
      { name: 'export_reports', resource: 'reports', action: 'export', category: 'reports',
        description: 'Can export reports to PDF/Excel' },
      { name: 'view_financial_reports', resource: 'reports', action: 'view_financial', category: 'reports',
        description: 'Can view detailed financial reports and profit analysis' },
      
      # Settings and Management permissions
      { name: 'view_settings', resource: 'settings', action: 'view', category: 'settings',
        description: 'Can view business and shop settings' },
      { name: 'edit_settings', resource: 'settings', action: 'edit', category: 'settings',
        description: 'Can modify business and shop settings' },
      { name: 'manage_users', resource: 'users', action: 'manage', category: 'settings',
        description: 'Can manage users and their permissions' },
      { name: 'view_dashboard', resource: 'dashboard', action: 'view', category: 'general',
        description: 'Can access main dashboard and overview' }
    ]
    
    # Create permissions
    permissions_data.each do |perm_data|
      Permission.find_or_create_by(name: perm_data[:name]) do |permission|
        permission.resource = perm_data[:resource]
        permission.action = perm_data[:action]
        permission.category = perm_data[:category]
        permission.description = perm_data[:description]
        permission.system_permission = false
      end
    end
    
    puts "✅ Created #{permissions_data.count} permissions"
  end
  
  def down
    Permission.delete_all
  end
end
