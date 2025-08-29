class Project < ApplicationRecord
  belongs_to :team
  has_many :project_updates, dependent: :destroy
  has_many :investments, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :vote_rounds, dependent: :destroy
  has_many :map_locations, dependent: :destroy
  
  has_many_attached :images
  has_one_attached :featured_image

  validates :title, :description, :category, :funding_goal, presence: true
  validates :funding_goal, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[draft published funded completed cancelled] }
  validates :category, inclusion: { in: %w[technology agriculture healthcare education fintech] }

  enum status: { draft: 0, published: 1, funded: 2, completed: 3, cancelled: 4 }

  scope :featured, -> { where(featured: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_category, ->(category) { where(category: category) }
  scope :active, -> { where(status: [:published, :funded]) }

  def funding_percentage
    return 0 if funding_goal.zero?
    
    (total_raised / funding_goal * 100).round(2)
  end

  def total_raised
    investments.confirmed.sum(:amount)
  end

  def days_remaining
    return 0 unless funding_deadline
    
    [(funding_deadline.to_date - Date.current).to_i, 0].max
  end

  def total_votes
    votes.count
  end

  def positive_votes
    votes.where(vote_type: 'positive').count
  end

  def negative_votes
    votes.where(vote_type: 'negative').count
  end

  def vote_score
    positive_votes - negative_votes
  end

  def can_receive_funding?
    published? && funding_deadline && funding_deadline > Time.current
  end

  def fully_funded?
    total_raised >= funding_goal
  end

  def update_status_based_on_funding!
    if fully_funded? && published?
      update!(status: :funded)
    end
  end
end

