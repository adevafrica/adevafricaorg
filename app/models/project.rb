class Project < ApplicationRecord
  belongs_to :team
  belongs_to :user, optional: true

  # File attachments - expanded from original
  has_many_attached :images
  has_one_attached :featured_image
  has_one_attached :logo
  has_one_attached :pitch_video
  has_one_attached :pitch_deck
  has_many_attached :screenshots
  has_many_attached :documents

  # Existing associations
  has_many :project_updates, dependent: :destroy
  has_many :investments, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :vote_rounds, dependent: :destroy
  has_many :map_locations, dependent: :destroy

  # New comprehensive associations
  has_many :investors, through: :investments, source: :user
  has_many :voters, through: :votes, source: :user
  has_many :project_collaborations, dependent: :destroy
  has_many :collaborators, through: :project_collaborations, source: :user
  has_many :project_skills, dependent: :destroy
  has_many :skills, through: :project_skills
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :hackathon_submissions, dependent: :destroy
  has_many :hackathons, through: :hackathon_submissions
  has_many :milestones, dependent: :destroy

  # Enums - expanded from original
  enum status: { 
    draft: 0, 
    published: 1, 
    funded: 2, 
    completed: 3, 
    cancelled: 4,
    pending_review: 5,
    approved: 6,
    rejected: 7,
    in_development: 8,
    archived: 9
  }

  enum category: {
    technology: 0,
    agriculture: 1,
    healthcare: 2,
    education: 3,
    fintech: 4,
    finance: 5,
    health: 6,
    energy: 7,
    transport: 8,
    entertainment: 9,
    social_impact: 10,
    other: 11
  }

  enum funding_stage: {
    idea: 0,
    prototype: 1,
    mvp: 2,
    early_stage: 3,
    growth_stage: 4,
    scale_stage: 5
  }

  # Validations - enhanced from original
  validates :title, :description, :category, :funding_goal, presence: true
  validates :funding_goal, numericality: { greater_than: 0 }
  validates :title, length: { minimum: 3, maximum: 100 }
  validates :description, length: { minimum: 10, maximum: 5000 }
  validates :short_description, presence: true, length: { maximum: 200 }
  validates :funding_stage, presence: true
  validates :github_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }
  validates :demo_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }
  validates :website_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }

  # Scopes - enhanced from original
  scope :featured, -> { where(featured: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_category, ->(category) { where(category: category) }
  scope :active, -> { where(status: [:published, :funded, :approved, :in_development]) }
  scope :by_funding_stage, ->(stage) { where(funding_stage: stage) }
  scope :seeking_funding, -> { where('funding_goal > ?', :total_raised) }
  scope :popular, -> { order(vote_count: :desc, view_count: :desc) }
  scope :trending, -> { where('created_at > ?', 30.days.ago).order(vote_count: :desc) }

  # Callbacks
  before_save :calculate_funding_percentage
  after_create :create_initial_update
  after_update :notify_followers, if: :saved_change_to_status?

  def funding_percentage
    return 0 if funding_goal.zero?
    (total_raised / funding_goal * 100).round(2)
  end

  def total_raised
    investments.confirmed.sum(:amount)
  end

  def current_funding
    total_raised
  end

  def days_remaining
    return 0 unless funding_deadline
    [(funding_deadline.to_date - Date.current).to_i, 0].max
  end

  def total_votes
    votes.count
  end

  def positive_votes
    votes.where(vote_type: 'positive').count
  end

  def negative_votes
    votes.where(vote_type: 'negative').count
  end

  def vote_score
    positive_votes - negative_votes
  end

  def average_rating
    votes.average(:rating) || 0
  end

  def can_receive_funding?
    (published? || approved?) && funding_deadline && funding_deadline > Time.current
  end

  def fully_funded?
    total_raised >= funding_goal
  end

  def active_funding?
    return false unless funding_deadline
    Date.current <= funding_deadline && !fully_funded?
  end

  def can_be_voted_by?(user)
    return false unless user
    return false if user == self.user || user == self.team&.leader
    !votes.exists?(user: user)
  end

  def team_members
    members = []
    members << user if user
    members << team.leader if team&.leader
    members + collaborators
  end

  def progress_percentage
    return 0 unless milestones.any?
    completed_milestones = milestones.where(completed: true).count
    (completed_milestones.to_f / milestones.count * 100).round(2)
  end

  def roi_projection
    return 0 unless projected_revenue && funding_goal
    return 0 if funding_goal.zero?
    ((projected_revenue - funding_goal) / funding_goal * 100).round(2)
  end

  def investment_summary
    {
      total_raised: current_funding,
      investors_count: investors.count,
      funding_percentage: funding_percentage,
      days_remaining: days_remaining,
      average_investment: investors.any? ? (current_funding / investors.count).round(2) : 0
    }
  end

  def tech_stack_array
    tech_stack&.split(',')&.map(&:strip) || []
  end

  def social_proof
    {
      votes: total_votes,
      rating: average_rating,
      views: view_count || 0,
      followers: followers_count || 0,
      github_stars: github_stars || 0
    }
  end

  def next_milestone
    milestones.where(completed: false).order(:target_date).first
  end

  def recent_updates
    project_updates.order(created_at: :desc).limit(5)
  end

  def similar_projects
    Project.active
           .where(category: category)
           .where.not(id: id)
           .limit(4)
  end

  def increment_view_count!
    increment!(:view_count)
  end

  def update_status_based_on_funding!
    if fully_funded? && (published? || approved?)
      update!(status: :funded)
    end
  end

  private

  def calculate_funding_percentage
    # This will be calculated dynamically, no need to store
  end

  def create_initial_update
    project_updates.create!(
      title: "Project Created",
      content: "#{title} has been created and is now seeking support!",
      user: user || team&.leader
    )
  end

  def notify_followers
    # Implementation for notifying followers about status changes
    # This would typically use a background job
  end
end

