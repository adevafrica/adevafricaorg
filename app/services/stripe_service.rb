class StripeService
  def initialize
    Stripe.api_key = ENV['STRIPE_SECRET_KEY']
  end

  def create_checkout_session(investment)
    begin
      session = Stripe::Checkout::Session.create({
        payment_method_types: ['card'],
        line_items: [{
          price_data: {
            currency: 'usd',
            product_data: {
              name: "Investment in #{investment.project.title}",
              description: investment.project.description.truncate(500),
            },
            unit_amount: (investment.amount * 100).to_i, # Convert to cents
          },
          quantity: 1,
        }],
        mode: 'payment',
        success_url: "#{ENV['BASE_URL']}/projects/#{investment.project.id}?payment=success",
        cancel_url: "#{ENV['BASE_URL']}/projects/#{investment.project.id}?payment=cancelled",
        metadata: {
          investment_id: investment.id,
          project_id: investment.project.id,
          user_id: investment.user.id
        }
      })

      # Update investment with Stripe session ID
      investment.update!(stripe_session_id: session.id)

      {
        success: true,
        checkout_url: session.url,
        session_id: session.id
      }
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error: #{e.message}"
      {
        success: false,
        errors: [e.message]
      }
    end
  end

  def create_payment_intent(investment)
    begin
      intent = Stripe::PaymentIntent.create({
        amount: (investment.amount * 100).to_i,
        currency: 'usd',
        metadata: {
          investment_id: investment.id,
          project_id: investment.project.id,
          user_id: investment.user.id
        }
      })

      investment.update!(stripe_payment_intent_id: intent.id)

      {
        success: true,
        client_secret: intent.client_secret,
        payment_intent_id: intent.id
      }
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error: #{e.message}"
      {
        success: false,
        errors: [e.message]
      }
    end
  end

  def refund_payment(investment)
    return { success: false, errors: ['No payment to refund'] } unless investment.stripe_payment_intent_id

    begin
      refund = Stripe::Refund.create({
        payment_intent: investment.stripe_payment_intent_id,
        reason: 'requested_by_customer'
      })

      investment.update!(
        status: :refunded,
        refunded_at: Time.current,
        stripe_refund_id: refund.id
      )

      {
        success: true,
        refund_id: refund.id
      }
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe refund error: #{e.message}"
      {
        success: false,
        errors: [e.message]
      }
    end
  end

  def create_connect_account(user)
    begin
      account = Stripe::Account.create({
        type: 'express',
        country: 'US', # This should be dynamic based on user location
        email: user.email,
        capabilities: {
          card_payments: { requested: true },
          transfers: { requested: true },
        },
      })

      {
        success: true,
        account_id: account.id
      }
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe Connect error: #{e.message}"
      {
        success: false,
        errors: [e.message]
      }
    end
  end

  def create_account_link(account_id, user)
    begin
      account_link = Stripe::AccountLink.create({
        account: account_id,
        refresh_url: "#{ENV['BASE_URL']}/dashboard/stripe/refresh",
        return_url: "#{ENV['BASE_URL']}/dashboard/stripe/return",
        type: 'account_onboarding',
      })

      {
        success: true,
        url: account_link.url
      }
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe Account Link error: #{e.message}"
      {
        success: false,
        errors: [e.message]
      }
    end
  end
end

