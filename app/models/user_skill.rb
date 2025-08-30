class UserSkill < ApplicationRecord
  belongs_to :user
  belongs_to :skill

  validates :user_id, uniqueness: { scope: :skill_id }
  validates :proficiency_level, inclusion: { in: %w[beginner intermediate advanced expert] }
  validates :years_experience, numericality: { greater_than_or_equal_to: 0 }

  enum proficiency_level: {
    beginner: 0,
    intermediate: 1,
    advanced: 2,
    expert: 3
  }

  scope :by_proficiency, ->(level) { where(proficiency_level: level) }
  scope :experienced, -> { where('years_experience >= ?', 2) }
end

