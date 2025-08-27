class PaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_bill, only: [:new, :create]
  before_action :set_customer, only: [:index]
  
  layout 'dashboard'
  
  def index
    if @customer
      @payments = @customer.payments.includes(:bill, :user).order(payment_date: :desc)
    else
      @payments = current_user.payments.includes(:customer, :bill).order(payment_date: :desc)
    end
  end
  
  def show
    @payment = current_user.payments.find(params[:id])
  end
  
  def new
    @payment = @bill.payments.build
    @payment.customer = @bill.customer
    @payment.amount = @bill.outstanding_amount
  end
  
  def create
    @payment = @bill.payments.build(payment_params)
    @payment.customer = @bill.customer
    @payment.user = current_user
    
    # Validate payment amount doesn't exceed outstanding amount
    if @payment.amount > @bill.outstanding_amount
      @payment.errors.add(:amount, "cannot exceed outstanding amount of PKR #{@bill.outstanding_amount}")
      
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { 
          render json: { 
            success: false, 
            errors: @payment.errors.full_messages 
          }, status: :unprocessable_entity 
        }
      end
      return
    end
    
    if @payment.save
      # Recalculate bill status after payment
      @bill.reload # Reload to get fresh data
      @bill.update_status! if @bill.customer.present?
      @bill.reload # Reload again to get updated status
      
      respond_to do |format|
        format.html do
          if params[:customer_id]
            redirect_to customer_path(@bill.customer), notice: 'Payment recorded successfully.'
          else
            redirect_to bills_path, notice: 'Payment recorded successfully.'
          end
        end
        format.json do
          render json: { 
            success: true, 
            message: 'Payment recorded successfully.',
            payment: {
              amount: @payment.amount.to_f,
              method: @payment.payment_method,
              date: @payment.payment_date.strftime("%B %d, %Y")
            },
            bill: {
              id: @bill.id,
              total_paid: @bill.total_paid.to_f,
              outstanding_amount: @bill.outstanding_amount.to_f,
              status: @bill.status
            }
          }
        end
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { 
          render json: { 
            success: false, 
            errors: @payment.errors.full_messages 
          }, status: :unprocessable_entity 
        }
      end
    end
  rescue => e
    Rails.logger.error "Payment creation error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    respond_to do |format|
      format.html { redirect_to @bill, alert: 'An error occurred while processing the payment.' }
      format.json { 
        render json: { 
          success: false, 
          errors: ["An error occurred while processing the payment: #{e.message}"] 
        }, status: :internal_server_error 
      }
    end
  end
  
  private
  
  def set_bill
    if params[:customer_id]
      @bill = current_user.bills.find(params[:bill_id])
    else
      @bill = current_user.bills.find(params[:bill_id])
    end
  end
  
  def set_customer
    @customer = current_user.customers.find(params[:customer_id]) if params[:customer_id]
  end
  
  def payment_params
    params.require(:payment).permit(:amount, :payment_method, :payment_date, :notes)
  end
end
