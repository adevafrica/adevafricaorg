class Assistant < ApplicationRecord
  validates :name, :description, presence: true
  validates :assistant_type, inclusion: { in: %w[project_advisor financial_analyst market_researcher general] }
  validates :status, inclusion: { in: %w[active inactive maintenance] }

  enum assistant_type: { project_advisor: 0, financial_analyst: 1, market_researcher: 2, general: 3 }
  enum status: { active: 0, inactive: 1, maintenance: 2 }

  has_many :assistant_responses, dependent: :destroy

  scope :available, -> { where(status: :active) }

  def prompt_template
    settings&.dig('prompt_template') || default_prompt_template
  end

  def max_tokens
    settings&.dig('max_tokens') || 1000
  end

  def temperature
    settings&.dig('temperature') || 0.7
  end

  def model_name
    settings&.dig('model') || 'gpt-3.5-turbo'
  end

  def can_answer?(question_type = nil)
    return false unless active?
    
    case assistant_type
    when 'project_advisor'
      %w[project planning strategy development].any? { |keyword| question_type&.include?(keyword) }
    when 'financial_analyst'
      %w[finance investment funding budget].any? { |keyword| question_type&.include?(keyword) }
    when 'market_researcher'
      %w[market research competition analysis].any? { |keyword| question_type&.include?(keyword) }
    else
      true # general assistant can answer anything
    end
  end

  private

  def default_prompt_template
    case assistant_type
    when 'project_advisor'
      "You are a project advisor for African development projects. Provide practical, actionable advice based on the context provided."
    when 'financial_analyst'
      "You are a financial analyst specializing in African markets and development funding. Provide detailed financial insights and recommendations."
    when 'market_researcher'
      "You are a market researcher with expertise in African markets. Provide comprehensive market analysis and insights."
    else
      "You are a helpful assistant for the +A_DevAfrica platform. Provide accurate and helpful responses based on the context provided."
    end
  end
end

