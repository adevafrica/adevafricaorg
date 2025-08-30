class Mentorship < ApplicationRecord
  belongs_to :mentor, class_name: 'User'
  belongs_to :mentee, class_name: 'User'

  validates :mentor_id, uniqueness: { scope: :mentee_id }
  validates :status, presence: true
  validates :rating, numericality: { in: 1..5 }, allow_nil: true

  enum status: {
    pending: 0,
    active: 1,
    completed: 2,
    cancelled: 3
  }

  scope :active_mentorships, -> { where(status: :active) }
  scope :completed_mentorships, -> { where(status: :completed) }

  def duration_in_weeks
    return 0 unless start_date && end_date
    ((end_date - start_date) / 1.week).round
  end

  def can_be_rated?
    completed? && rating.nil?
  end
end

