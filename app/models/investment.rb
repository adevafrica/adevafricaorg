class Investment < ApplicationRecord
  belongs_to :user
  belongs_to :project

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[pending confirmed cancelled refunded] }
  validates :payment_method, inclusion: { in: %w[stripe mpesa bank_transfer] }

  enum status: { pending: 0, confirmed: 1, cancelled: 2, refunded: 3 }
  enum payment_method: { stripe: 0, mpesa: 1, bank_transfer: 2 }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_amount, -> { order(amount: :desc) }

  after_update :update_project_funding_status, if: :saved_change_to_status?

  def can_be_refunded?
    confirmed? && project.can_receive_funding?
  end

  def processing_fee
    # Calculate processing fee based on payment method
    case payment_method
    when 'stripe'
      (amount * 0.029 + 0.30).round(2) # Stripe's typical fee
    when 'mpesa'
      (amount * 0.01).round(2) # M-Pesa typical fee
    else
      0
    end
  end

  def net_amount
    amount - processing_fee
  end

  private

  def update_project_funding_status
    project.update_status_based_on_funding! if confirmed?
  end
end

