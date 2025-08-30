class ForumCategory < ApplicationRecord
  has_many :forum_posts, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :description, presence: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:sort_order, :name) }

  def posts_count
    forum_posts.count
  end

  def recent_post
    forum_posts.recent.first
  end
end

