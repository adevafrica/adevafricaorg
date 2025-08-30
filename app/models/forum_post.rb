class ForumPost < ApplicationRecord
  belongs_to :user
  belongs_to :forum_category

  has_many :forum_comments, dependent: :destroy
  has_many :post_votes, dependent: :destroy

  validates :title, presence: true, length: { minimum: 5, maximum: 200 }
  validates :content, presence: true, length: { minimum: 10 }
  validates :post_type, presence: true

  enum post_type: {
    discussion: 0,
    question: 1,
    announcement: 2,
    showcase: 3,
    help: 4
  }

  enum status: {
    active: 0,
    closed: 1,
    pinned: 2,
    archived: 3
  }

  scope :recent, -> { order(created_at: :desc) }
  scope :popular, -> { order(views_count: :desc, comments_count: :desc) }
  scope :by_type, ->(type) { where(post_type: type) }

  def points
    10 + (forum_comments.count * 2) + (post_votes.positive.count * 5)
  end

  def vote_score
    post_votes.positive.count - post_votes.negative.count
  end

  def increment_views!
    increment!(:views_count)
  end
end

