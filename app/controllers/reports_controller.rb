class ReportsController < ApplicationController
  before_action :authenticate_user!
  
  layout 'dashboard'
  
  def index
    # Date range setup
    @start_date = params[:start_date]&.to_date || 30.days.ago.to_date
    @end_date = params[:end_date]&.to_date || Date.current
    
    # Sales Analytics
    @total_sales = current_user.sales.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day).sum(:total_amount)
    @total_sales_count = current_user.sales.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day).count
    @average_sale_value = @total_sales_count > 0 ? (@total_sales / @total_sales_count) : 0
    
    # Cash vs Credit Sales
    @cash_sales = current_user.sales.joins(:bill).where(bills: { bill_type: 'cash' }, created_at: @start_date.beginning_of_day..@end_date.end_of_day).sum(:total_amount)
    @credit_sales = current_user.sales.joins(:bill).where(bills: { bill_type: 'credit' }, created_at: @start_date.beginning_of_day..@end_date.end_of_day).sum(:total_amount)
    @direct_sales = current_user.sales.where(bill_id: nil, created_at: @start_date.beginning_of_day..@end_date.end_of_day).sum(:total_amount)
    
    # Top selling products
    @top_products = current_user.sales
                                .joins(:product)
                                .where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
                                .group('products.name', 'products.id')
                                .select('products.name, products.id, SUM(sales.quantity) as total_quantity, SUM(sales.total_amount) as total_revenue')
                                .order('total_quantity DESC')
                                .limit(10)
    
    # Customer Analytics
    @total_customers = current_user.customers.count
    @customers_with_pending_bills = current_user.customers.joins(:bills).where(bills: { status: ['pending', 'partial'] }).distinct.count
    @total_receivables = current_user.bills.where(status: ['pending', 'partial']).sum { |bill| bill.outstanding_amount }
    @total_paid_amount = current_user.payments.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day).sum(:amount)
    
    # Daily sales for chart
    @daily_sales = current_user.sales
                               .where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
                               .group('DATE(created_at)')
                               .sum(:total_amount)
    
    # Monthly comparison
    current_month_sales = current_user.sales.where(created_at: Date.current.beginning_of_month..Date.current.end_of_month).sum(:total_amount)
    last_month_sales = current_user.sales.where(created_at: 1.month.ago.beginning_of_month..1.month.ago.end_of_month).sum(:total_amount)
    @monthly_growth = last_month_sales > 0 ? ((current_month_sales - last_month_sales) / last_month_sales * 100) : 0
    
    # Inventory alerts
    products = current_user.products.includes(:sales)
    @low_stock_products = products.select { |p| p.quantity <= p.minimum_stock_level }
    @out_of_stock_products = products.select { |p| p.quantity == 0 }
    @expiring_products = products.select { |p| p.expiry_status.in?(['critical', 'warning']) }
    
    @low_stock_count = @low_stock_products.count
    @out_of_stock_count = @out_of_stock_products.count
    @expiring_count = @expiring_products.count
    
    # Profit Analysis
    @total_cost = current_user.sales
                              .joins(:product)
                              .where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
                              .sum('sales.quantity * products.buying_price')
    @total_profit = @total_sales - @total_cost
    @profit_margin = @total_sales > 0 ? ((@total_profit / @total_sales) * 100) : 0
    
    # Category Performance
    @category_performance = current_user.sales
                                        .joins(:product)
                                        .where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
                                        .group('products.category')
                                        .select('products.category, SUM(sales.total_amount) as total_revenue, SUM(sales.quantity) as total_quantity')
                                        .order('total_revenue DESC')
                                        .limit(5)
    
    # Payment Method Analysis
    @payment_methods = current_user.payments
                                   .where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
                                   .group(:payment_method)
                                   .sum(:amount)
    
    # Recent Activities
    @recent_bills = current_user.bills.includes(:customer, :bill_items).order(created_at: :desc).limit(5)
    @recent_payments = current_user.payments.includes(:customer, :bill).order(created_at: :desc).limit(5)
    
    # Growth trends
    @weekly_growth = calculate_weekly_growth
    @daily_growth = calculate_daily_growth
  end
  
  private
  
  def calculate_weekly_growth
    current_week_sales = current_user.sales.where(created_at: 1.week.ago..Time.current).sum(:total_amount)
    previous_week_sales = current_user.sales.where(created_at: 2.weeks.ago..1.week.ago).sum(:total_amount)
    
    return 0 if previous_week_sales == 0
    ((current_week_sales - previous_week_sales) / previous_week_sales * 100).round(1)
  end
  
  def calculate_daily_growth
    today_sales = current_user.sales.where(created_at: Date.current.all_day).sum(:total_amount)
    yesterday_sales = current_user.sales.where(created_at: 1.day.ago.all_day).sum(:total_amount)
    
    return 0 if yesterday_sales == 0
    ((today_sales - yesterday_sales) / yesterday_sales * 100).round(1)
  end
end
