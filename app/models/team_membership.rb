class TeamMembership < ApplicationRecord
  belongs_to :user
  belongs_to :team

  validates :role, inclusion: { in: %w[owner member] }
  validates :user_id, uniqueness: { scope: :team_id }

  enum role: { owner: 0, member: 1 }

  scope :active, -> { where(active: true) }
end

