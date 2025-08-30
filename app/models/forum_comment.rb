class ForumComment < ApplicationRecord
  belongs_to :user
  belongs_to :forum_post
  belongs_to :parent_comment, class_name: 'ForumComment', optional: true

  has_many :replies, class_name: 'ForumComment', foreign_key: 'parent_comment_id', dependent: :destroy
  has_many :comment_votes, dependent: :destroy

  validates :content, presence: true, length: { minimum: 3 }

  scope :top_level, -> { where(parent_comment_id: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def points
    5 + (comment_votes.positive.count * 2)
  end

  def vote_score
    comment_votes.positive.count - comment_votes.negative.count
  end

  def is_reply?
    parent_comment_id.present?
  end
end

