class Pool < ApplicationRecord
  has_many :pool_contributions, dependent: :destroy
  has_many :users, through: :pool_contributions
  
  has_one_attached :image

  validates :name, :description, :target_amount, presence: true
  validates :target_amount, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[active paused closed] }
  validates :pool_type, inclusion: { in: %w[investment grant emergency community] }

  enum status: { active: 0, paused: 1, closed: 2 }
  enum pool_type: { investment: 0, grant: 1, emergency: 2, community: 3 }

  scope :available, -> { where(status: :active) }
  scope :by_type, ->(type) { where(pool_type: type) }

  def total_contributed
    pool_contributions.confirmed.sum(:amount)
  end

  def contribution_percentage
    return 0 if target_amount.zero?
    
    (total_contributed / target_amount * 100).round(2)
  end

  def total_contributors
    pool_contributions.confirmed.distinct.count(:user_id)
  end

  def can_contribute?
    active? && (deadline.nil? || deadline > Time.current)
  end

  def fully_funded?
    total_contributed >= target_amount
  end

  def days_remaining
    return nil unless deadline
    
    [(deadline.to_date - Date.current).to_i, 0].max
  end
end

