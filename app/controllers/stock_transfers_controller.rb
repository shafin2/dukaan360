class StockTransfersController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_business_access
  before_action :set_stock_transfer, only: [:show, :approve, :reject, :complete, :cancel]
  layout 'dashboard'
  
  def index
    if current_user.business_owner?
      # Business admin sees all transfers in their business
      @transfers = current_user.business.stock_transfers
                              .includes(:product, :from_shop, :to_shop, :initiated_by, :approved_by)
                              .order(created_at: :desc)
                              .paginate(page: params[:page], per_page: 20)
    else
      # Workers see transfers involving their shop
      @transfers = StockTransfer.where(
        "(from_shop_id = ? OR to_shop_id = ?) AND business_id = ?", 
        current_user.shop.id, current_user.shop.id, current_user.business.id
      ).includes(:product, :from_shop, :to_shop, :initiated_by, :approved_by)
       .order(created_at: :desc)
       .paginate(page: params[:page], per_page: 20)
    end
    
    # Filter by status if provided
    if params[:status].present?
      @transfers = @transfers.where(status: params[:status])
    end
    
    @pending_approvals = current_user.business_owner? ? 
      current_user.business.stock_transfers.pending.count : 0
  end
  
  def show
    # Transfer details
  end
  
  def new
    unless current_user.can?('manage_inventory')
      redirect_to stock_transfers_path, alert: 'You do not have permission to request transfers.'
      return
    end
    
    @transfer = StockTransfer.new
    @products = current_user.business.products
                           .joins(:shop_inventories)
                           .where(shop_inventories: { shop: current_user.shop })
                           .where('shop_inventories.quantity > 0')
                           .distinct
    @shops = current_user.business.shops.where.not(id: current_user.shop.id)
  end
  
  def create
    unless current_user.can?('manage_inventory')
      redirect_to stock_transfers_path, alert: 'You do not have permission to request transfers.'
      return
    end
    
    @transfer = StockTransfer.new(transfer_params)
    @transfer.initiated_by = current_user
    @transfer.from_shop = current_user.shop
    @transfer.business = current_user.business
    
    if @transfer.save
      # Send notification to business admins
      redirect_to stock_transfers_path, 
        notice: 'Transfer request submitted successfully. Waiting for approval.'
    else
      @products = current_user.business.products
                             .joins(:shop_inventories)
                             .where(shop_inventories: { shop: current_user.shop })
                             .where('shop_inventories.quantity > 0')
                             .distinct
      @shops = current_user.business.shops.where.not(id: current_user.shop.id)
      render :new, status: :unprocessable_entity
    end
  end
  
  def approve
    unless current_user.business_owner?
      redirect_to stock_transfers_path, alert: 'Only business admins can approve transfers.'
      return
    end
    
    if @transfer.approve!(current_user)
      redirect_to stock_transfer_path(@transfer), 
        notice: 'Transfer approved successfully.'
    else
      redirect_to stock_transfer_path(@transfer), 
        alert: "Failed to approve transfer: #{@transfer.errors.full_messages.join(', ')}"
    end
  end
  
  def reject
    unless current_user.business_owner?
      redirect_to stock_transfers_path, alert: 'Only business admins can reject transfers.'
      return
    end
    
    reason = params[:rejection_reason] || 'No reason provided'
    
    if @transfer.update(status: 'rejected', cancellation_reason: reason, cancelled_at: Time.current)
      redirect_to stock_transfers_path, 
        notice: 'Transfer rejected.'
    else
      redirect_to stock_transfer_path(@transfer), 
        alert: 'Failed to reject transfer.'
    end
  end
  
  def complete
    unless current_user.business_owner?
      redirect_to stock_transfers_path, alert: 'Only business admins can complete transfers.'
      return
    end
    
    if @transfer.complete!
      redirect_to stock_transfer_path(@transfer), 
        notice: 'Transfer completed successfully. Stock has been moved.'
    else
      redirect_to stock_transfer_path(@transfer), 
        alert: "Failed to complete transfer: #{@transfer.errors.full_messages.join(', ')}"
    end
  end
  
  def cancel
    unless @transfer.initiated_by == current_user || current_user.business_owner?
      redirect_to stock_transfers_path, alert: 'You can only cancel your own transfers.'
      return
    end
    
    reason = params[:cancellation_reason] || 'Cancelled by user'
    
    if @transfer.cancel!(reason)
      redirect_to stock_transfers_path, 
        notice: 'Transfer cancelled.'
    else
      redirect_to stock_transfer_path(@transfer), 
        alert: 'Failed to cancel transfer.'
    end
  end
  
  def pending_approvals
    unless current_user.business_owner?
      redirect_to stock_transfers_path, alert: 'Access denied.'
      return
    end
    
    @pending_transfers = current_user.business.stock_transfers
                                    .pending
                                    .includes(:product, :from_shop, :to_shop, :initiated_by)
                                    .order(created_at: :asc)
  end
  
  def bulk_approve
    unless current_user.business_owner?
      redirect_to stock_transfers_path, alert: 'Only business admins can bulk approve transfers.'
      return
    end
    
    transfer_ids = params[:transfer_ids] || []
    approved_count = 0
    failed_count = 0
    
    transfer_ids.each do |id|
      transfer = current_user.business.stock_transfers.find(id)
      if transfer.approve!(current_user)
        approved_count += 1
      else
        failed_count += 1
      end
    rescue => e
      failed_count += 1
    end
    
    message = "#{approved_count} transfers approved"
    message += ", #{failed_count} failed" if failed_count > 0
    
    redirect_to pending_approvals_stock_transfers_path, notice: message
  end
  
  private
  
  def set_stock_transfer
    if current_user.business_owner?
      @transfer = current_user.business.stock_transfers.find(params[:id])
    else
      @transfer = StockTransfer.where(
        "(from_shop_id = ? OR to_shop_id = ?) AND business_id = ?", 
        current_user.shop.id, current_user.shop.id, current_user.business.id
      ).find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to stock_transfers_path, alert: 'Transfer not found or access denied.'
  end
  
  def transfer_params
    params.require(:stock_transfer).permit(
      :product_id, :to_shop_id, :quantity, :reason
    )
  end
  
  def ensure_business_access
    unless current_user.business.present?
      redirect_to root_path, alert: 'Access denied. Please contact administrator.'
    end
  end
end
