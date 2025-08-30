class UserBadge < ApplicationRecord
  belongs_to :user
  belongs_to :badge

  validates :user_id, uniqueness: { scope: :badge_id }

  scope :recent, -> { order(earned_at: :desc) }

  def points
    badge.points
  end
end

