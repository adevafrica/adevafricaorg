class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # User types - expanded from original
  enum role: {
    member: 0,
    developer: 1,
    designer: 2,
    investor: 3,
    mentor: 4,
    partner: 5,
    admin: 6
  }

  # Profile attributes
  has_one_attached :avatar
  has_one_attached :resume
  has_many_attached :portfolio_images

  # Existing associations
  has_many :team_memberships, dependent: :destroy
  has_many :teams, through: :team_memberships
  has_many :investments, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :pool_contributions, dependent: :destroy

  # New comprehensive associations
  has_many :projects, dependent: :destroy
  has_many :mentorships_as_mentor, class_name: 'Mentorship', foreign_key: 'mentor_id'
  has_many :mentorships_as_mentee, class_name: 'Mentorship', foreign_key: 'mentee_id'
  has_many :forum_posts, dependent: :destroy
  has_many :forum_comments, dependent: :destroy
  has_many :hackathon_participations, dependent: :destroy
  has_many :user_skills, dependent: :destroy
  has_many :skills, through: :user_skills
  has_many :user_badges, dependent: :destroy
  has_many :badges, through: :user_badges
  has_many :notifications, dependent: :destroy
  has_many :chat_messages, dependent: :destroy
  has_many :project_collaborations, dependent: :destroy
  has_many :collaborated_projects, through: :project_collaborations, source: :project

  # Validations
  validates :first_name, :last_name, presence: true
  validates :role, presence: true
  validates :bio, length: { maximum: 1000 }, allow_blank: true
  validates :github_username, uniqueness: { allow_blank: true }
  validates :linkedin_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }
  validates :portfolio_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }

  # Scopes
  scope :verified, -> { where(verified: true) }
  scope :active, -> { where(active: true) }
  scope :by_role, ->(role) { where(role: role) }

  # Callbacks
  before_create :generate_username
  after_create :create_default_profile

  def full_name
    "#{first_name} #{last_name}"
  end

  def display_name
    username.presence || full_name.presence || email
  end

  def admin?
    role == 'admin'
  end

  def investor?
    role == 'investor'
  end

  def member?
    role == 'member'
  end

  def developer?
    role == 'developer'
  end

  def designer?
    role == 'designer'
  end

  def mentor?
    role == 'mentor'
  end

  def partner?
    role == 'partner'
  end

  def total_investments
    investments.sum(:amount)
  end

  def total_votes
    votes.count
  end

  def experience_points
    (user_badges.sum(:points) || 0) + 
    (projects.sum(:points) || 0) + 
    (forum_posts.sum(:points) || 0)
  end

  def level
    case experience_points
    when 0..99 then 'Beginner'
    when 100..499 then 'Intermediate'
    when 500..999 then 'Advanced'
    when 1000..4999 then 'Expert'
    else 'Master'
    end
  end

  def investor_profile
    return nil unless investor?
    {
      total_invested: investments.sum(:amount),
      active_investments: investments.where(status: 'active').count,
      roi: calculate_roi,
      portfolio_value: calculate_portfolio_value
    }
  end

  def mentor_rating
    return 0 unless mentor?
    mentorships_as_mentor.average(:rating) || 0
  end

  def can_vote_on?(project)
    return false if project.user == self
    !votes.exists?(project: project)
  end

  def location_data
    {
      country: country,
      city: city,
      timezone: timezone
    }
  end

  private

  def generate_username
    return if username.present?
    
    base_username = "#{first_name}#{last_name}".downcase.gsub(/[^a-z0-9]/, '')
    username_candidate = base_username
    counter = 1
    
    while User.exists?(username: username_candidate)
      username_candidate = "#{base_username}#{counter}"
      counter += 1
    end
    
    self.username = username_candidate
  end

  def create_default_profile
    update(
      active: true,
      email_notifications: true,
      profile_visibility: 'public'
    )
  end

  def calculate_roi
    return 0 if investments.empty?
    
    total_invested = investments.sum(:amount)
    total_returns = investments.sum(:current_value) || total_invested
    
    return 0 if total_invested.zero?
    ((total_returns - total_invested) / total_invested * 100).round(2)
  end

  def calculate_portfolio_value
    investments.sum(:current_value) || investments.sum(:amount)
  end
end

