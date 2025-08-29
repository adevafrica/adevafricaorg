class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :project
  belongs_to :vote_round, optional: true

  validates :vote_type, inclusion: { in: %w[positive negative abstain] }
  validates :user_id, uniqueness: { scope: :project_id, message: "can only vote once per project" }

  enum vote_type: { positive: 0, negative: 1, abstain: 2 }

  scope :recent, -> { order(created_at: :desc) }
  scope :for_round, ->(round) { where(vote_round: round) }

  after_create :broadcast_vote_update

  def weight
    # Vote weight could be based on user's investment amount or role
    case user.role
    when 'admin'
      3
    when 'investor'
      user.investments.where(project: project).sum(:amount) / 1000.0 + 1
    else
      1
    end
  end

  private

  def broadcast_vote_update
    # Broadcast real-time vote updates using ActionCable
    VotesChannel.broadcast_to(project, {
      total_votes: project.total_votes,
      positive_votes: project.positive_votes,
      negative_votes: project.negative_votes,
      vote_score: project.vote_score
    })
  end
end

