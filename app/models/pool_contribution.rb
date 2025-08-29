class PoolContribution < ApplicationRecord
  belongs_to :user
  belongs_to :pool

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[pending confirmed cancelled refunded] }

  enum status: { pending: 0, confirmed: 1, cancelled: 2, refunded: 3 }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_amount, -> { order(amount: :desc) }

  def can_be_refunded?
    confirmed? && pool.can_contribute?
  end
end

