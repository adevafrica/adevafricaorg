class ProjectUpdate < ApplicationRecord
  belongs_to :project

  validates :title, :content, presence: true
  validates :update_type, inclusion: { in: %w[milestone progress announcement] }

  enum update_type: { milestone: 0, progress: 1, announcement: 2 }

  has_many_attached :images

  scope :recent, -> { order(created_at: :desc) }
  scope :published, -> { where(published: true) }
  scope :by_type, ->(type) { where(update_type: type) }

  def excerpt(limit = 150)
    content.truncate(limit)
  end
end

