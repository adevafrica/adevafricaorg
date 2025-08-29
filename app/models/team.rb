class Team < ApplicationRecord
  has_many :team_memberships, dependent: :destroy
  has_many :users, through: :team_memberships
  has_many :projects, dependent: :destroy
  
  has_one_attached :logo

  validates :name, :description, presence: true
  validates :name, uniqueness: true

  scope :active, -> { where(active: true) }

  def owner
    team_memberships.find_by(role: 'owner')&.user
  end

  def members
    users.joins(:team_memberships).where(team_memberships: { role: 'member' })
  end

  def total_funding_raised
    projects.sum { |project| project.total_raised }
  end

  def total_projects
    projects.count
  end

  def successful_projects
    projects.where(status: [:funded, :completed]).count
  end
end

