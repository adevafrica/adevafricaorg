class Badge < ApplicationRecord
  has_many :user_badges, dependent: :destroy
  has_many :users, through: :user_badges

  has_one_attached :icon

  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :points, numericality: { greater_than: 0 }
  validates :badge_type, presence: true

  enum badge_type: {
    achievement: 0,
    participation: 1,
    contribution: 2,
    milestone: 3,
    special: 4
  }

  enum rarity: {
    common: 0,
    uncommon: 1,
    rare: 2,
    epic: 3,
    legendary: 4
  }

  scope :by_type, ->(type) { where(badge_type: type) }
  scope :by_rarity, ->(rarity) { where(rarity: rarity) }

  def earned_count
    user_badges.count
  end

  def rarity_percentage
    return 0 if User.count.zero?
    (earned_count.to_f / User.count * 100).round(2)
  end
end

