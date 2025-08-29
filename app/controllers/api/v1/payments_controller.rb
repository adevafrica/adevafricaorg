class Api::V1::PaymentsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:webhook]
  skip_before_action :authenticate_user!, only: [:webhook]

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
    investment_id = payment_intent['metadata']['investment_id']
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

