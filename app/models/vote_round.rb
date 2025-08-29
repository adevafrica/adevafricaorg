class VoteRound < ApplicationRecord
  belongs_to :project
  has_many :votes, dependent: :destroy

  validates :title, :description, presence: true
  validates :status, inclusion: { in: %w[upcoming active closed] }

  enum status: { upcoming: 0, active: 1, closed: 2 }

  scope :current, -> { where(status: :active) }
  scope :recent, -> { order(created_at: :desc) }

  def can_vote?
    active? && (end_date.nil? || end_date > Time.current)
  end

  def total_votes
    votes.count
  end

  def results
    {
      positive: votes.positive.count,
      negative: votes.negative.count,
      abstain: votes.abstain.count,
      total: total_votes
    }
  end

  def participation_rate
    return 0 if project.team.users.count.zero?
    
    (total_votes.to_f / project.team.users.count * 100).round(2)
  end

  def close_round!
    update!(status: :closed, end_date: Time.current)
  end
end

