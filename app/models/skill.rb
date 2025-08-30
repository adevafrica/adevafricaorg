class Skill < ApplicationRecord
  has_many :user_skills, dependent: :destroy
  has_many :users, through: :user_skills
  has_many :project_skills, dependent: :destroy
  has_many :projects, through: :project_skills

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :category, presence: true

  enum category: {
    programming: 0,
    design: 1,
    marketing: 2,
    business: 3,
    data_science: 4,
    mobile: 5,
    web: 6,
    ai_ml: 7,
    blockchain: 8,
    devops: 9,
    other: 10
  }

  scope :popular, -> { joins(:user_skills).group('skills.id').order('COUNT(user_skills.id) DESC') }
  scope :by_category, ->(category) { where(category: category) }

  def self.trending
    joins(:user_skills)
      .where(user_skills: { created_at: 30.days.ago..Time.current })
      .group('skills.id')
      .order('COUNT(user_skills.id) DESC')
      .limit(10)
  end

  def users_count
    users.count
  end

  def projects_count
    projects.count
  end
end

