class AssistantResponse < ApplicationRecord
  belongs_to :assistant
  belongs_to :user
  belongs_to :project, optional: true

  validates :question, :response, presence: true
  validates :status, inclusion: { in: %w[pending completed error] }

  enum status: { pending: 0, completed: 1, error: 2 }

  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }
  scope :for_project, ->(project) { where(project: project) }

  def tokens_used
    metadata&.dig('tokens_used') || 0
  end

  def processing_time
    return nil unless completed_at && created_at
    
    completed_at - created_at
  end

  def cost_estimate
    # Rough cost estimation based on tokens used
    # This would depend on the actual LLM provider pricing
    tokens_used * 0.0001 # Example: $0.0001 per token
  end
end

