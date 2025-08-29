class Api::V1::PaymentsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:webhook]
  skip_before_action :authenticate_user!, only: [:webhook]

  def create
    project = Project.find(params[:project_id])
    amount = params[:amount].to_i
    payment_method_nonce = params[:payment_method_nonce]
    payment_gateway = params[:payment_gateway]

    case payment_gateway
    when 'stripe'
      # Handle Stripe payment
      charge = Stripe::Charge.create(
        amount: amount,
        currency: 'usd',
        source: payment_method_nonce,
        description: "Investment in #{project.title}"
      )
      if charge.paid
        # Record investment
        investment = Investment.create!(
          user: current_user,
          project: project,
          amount: amount,
          payment_method: 'stripe',
          transaction_id: charge.id
        )
        render json: { success: true, message: 'Payment successful', investment: investment }, status: :ok
      else
        render json: { success: false, message: 'Payment failed' }, status: :bad_request
      end
    when 'mpesa'
      # Handle M-Pesa payment (simplified for demonstration)
      # In a real application, this would involve M-Pesa API integration (STK Push, C2B, B2C)
      # For now, we'll simulate a successful M-Pesa payment
      if amount > 0
        investment = Investment.create!(
          user: current_user,
          project: project,
          amount: amount,
          payment_method: 'mpesa',
          transaction_id: "MPESA_#{SecureRandom.hex(10)}"
        )
        render json: { success: true, message: 'M-Pesa payment initiated. Please complete the transaction on your phone.', investment: investment }, status: :ok
      else
        render json: { success: false, message: 'Invalid M-Pesa amount' }, status: :bad_request
      end
    when 'flutterwave'
      # Handle Flutterwave payment (simplified for demonstration)
      # In a real application, this would would involve Flutterwave API integration
      if amount > 0
        investment = Investment.create!(
          user: current_user,
          project: project,
          amount: amount,
          payment_method: 'flutterwave',
          transaction_id: "FLUTTERWAVE_#{SecureRandom.hex(10)}"
        )
        render json: { success: true, message: 'Flutterwave payment initiated.', investment: investment }, status: :ok
      else
        render json:: { success: false, message: 'Invalid Flutterwave amount' }, status: :bad_request
      end
    when 'paystack'
      # Handle Paystack payment (simplified for demonstration)
      # In a real application, this would involve Paystack API integration
      if amount > 0
        investment = Investment.create!(
          user: current_user,
          project: project,
          amount: amount,
          payment_method: 'paystack',
          transaction_id: "PAYSTACK_#{SecureRandom.hex(10)}"
        )
        render json: { success: true, message: 'Paystack payment initiated.', investment: investment }, status: :ok
      else
        render json: { success: false, message: 'Invalid Paystack amount' }, status: :bad_request
      end
    when 'crypto'
      # Handle Crypto payment (simplified for demonstration)
      # In a real application, this would involve blockchain integration (e.g., Ethereum, Celo)
      if amount > 0
        investment = Investment.create!(
          user: (current_user), # Assuming current_user is available
          project: project,
          amount: amount,
          payment_method: 'crypto',
          transaction_id: "CRYPTO_#{SecureRandom.hex(10)}"
        )
        render json: { success: true, message: 'Crypto payment initiated. Please complete the transaction.', investment: investment }, status: :ok
      else
        render json: { success: false, message: 'Invalid crypto amount' }, status: :bad_request
      end
    else
      render json: { success: false, message: 'Unsupported payment gateway' }, status: :bad_request
    end
  rescue StandardError => e
    render json: { success: false, message: e.message }, status: :internal_server_error
  end

  def webhook
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = ENV['STRIPE_WEBHOOK_SECRET']

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError => e
      render json: { error: 'Invalid payload' }, status: 400
      return
    rescue Stripe::SignatureVerificationError => e
      render json: { error: 'Invalid signature' }, status: 400
      return
    end

    case event['type']
    when 'checkout.session.completed'
      handle_checkout_completed(event['data']['object'])
    when 'payment_intent.succeeded'
      handle_payment_succeeded(event['data']['object'])
    when 'payment_intent.payment_failed'
      handle_payment_failed(event['data']['object'])
    else
      Rails.logger.info "Unhandled event type: #{event['type']}"
    end

    render json: { received: true }
  end

  private

  def handle_checkout_completed(session)
    investment_id = session['metadata']['investment_id']
    investment = Investment.find_by(id: investment_id)

    if investment
      ProcessInvestmentJob.perform_async(investment.id, session.to_json)
    else
      Rails.logger.error "Investment not found for session: #{session['id']}"
    end
  end

  def handle_payment_succeeded(payment_intent)
    investment_id = Investment.find_by(id: payment_intent['metadata']['investment_id'])
    investment = Investment.find_by(id: investment_id)

    if investment
      investment.update!(
        status: :confirmed,
        stripe_payment_intent_id: payment_intent['id'],
        confirmed_at: Time.current
      )
      
      # Update project funding status
      investment.project.update_status_based_on_funding!
      
      # Send confirmation email
      UserMailer.investment_confirmed(investment).deliver_later
    end
  end

  def handle_payment_failed(payment_intent)
    investment_id = payment_intent['metadata']['investment_id']
    investment = Investment.find_by(id: investment_id)

    if investment
      investment.update!(
        status: :cancelled,
        failure_reason: payment_intent['last_payment_error']&.dig('message')
      )
    end
  end
end

