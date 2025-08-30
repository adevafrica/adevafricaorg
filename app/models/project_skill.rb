class ProjectSkill < ApplicationRecord
  belongs_to :project
  belongs_to :skill

  validates :project_id, uniqueness: { scope: :skill_id }
  validates :importance_level, inclusion: { in: %w[nice_to_have important critical] }

  enum importance_level: {
    nice_to_have: 0,
    important: 1,
    critical: 2
  }
end

