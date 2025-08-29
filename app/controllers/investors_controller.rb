class InvestorsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_investor_role

  def dashboard
    @investor_stats = {
      total_investments: current_user.investments.sum(:amount),
      active_investments: current_user.investments.active.count,
      portfolio_projects: current_user.investments.includes(:project).map(&:project).uniq.count,
      roi: calculate_roi
    }
    
    @recent_investments = current_user.investments.includes(:project).recent.limit(5)
    @portfolio_projects = current_user.investments.includes(:project).map(&:project).uniq.first(6)
    @investment_opportunities = Project.published.fundable.limit(6)
    @performance_data = generate_performance_data
  end

  def portfolio
    @investments = current_user.investments.includes(:project, :user)
                              .page(params[:page]).per(10)
    
    if params[:status].present?
      @investments = @investments.where(status: params[:status])
    end
    
    if params[:project_category].present?
      @investments = @investments.joins(:project)
                                .where(projects: { category: params[:project_category] })
    end
    
    @portfolio_summary = {
      total_invested: @investments.sum(:amount),
      total_projects: @investments.map(&:project).uniq.count,
      avg_investment: @investments.average(:amount),
      success_rate: calculate_success_rate(@investments)
    }
  end

  def opportunities
    @projects = Project.published.fundable.includes(:team, :investments)
    
    if params[:category].present?
      @projects = @projects.where(category: params[:category])
    end
    
    if params[:funding_stage].present?
      @projects = @projects.where(funding_stage: params[:funding_stage])
    end
    
    if params[:min_amount].present?
      @projects = @projects.where('funding_goal >= ?', params[:min_amount])
    end
    
    if params[:max_amount].present?
      @projects = @projects.where('funding_goal <= ?', params[:max_amount])
    end
    
    @projects = @projects.page(params[:page]).per(12)
  end

  def analytics
    @analytics_data = {
      investment_timeline: generate_investment_timeline,
      category_distribution: generate_category_distribution,
      roi_analysis: generate_roi_analysis,
      risk_assessment: generate_risk_assessment
    }
  end

  def leaderboard
    @top_investors = User.joins(:investments)
                        .where(role: 'investor')
                        .group('users.id')
                        .order('SUM(investments.amount) DESC')
                        .limit(50)
                        .includes(:investments)
    
    @current_user_rank = calculate_user_rank(current_user)
  end

  def invest
    @project = Project.find(params[:project_id])
    @investment = Investment.new
    
    unless @project.fundable?
      redirect_to @project, alert: 'This project is not currently accepting investments.'
      return
    end
  end

  def create_investment
    @project = Project.find(params[:project_id])
    @investment = @project.investments.build(investment_params)
    @investment.user = current_user
    @investment.status = 'pending'

    if @investment.save
      # Process payment
      ProcessInvestmentJob.perform_later(@investment.id)
      redirect_to investor_dashboard_path, notice: 'Investment initiated successfully.'
    else
      render :invest
    end
  end

  private

  def ensure_investor_role
    unless current_user.investor? || current_user.admin?
      redirect_to root_path, alert: 'Access denied. Investor role required.'
    end
  end

  def calculate_roi
    total_invested = current_user.investments.sum(:amount)
    return 0 if total_invested.zero?
    
    total_returns = current_user.investments.successful.sum(:returns_amount)
    ((total_returns - total_invested) / total_invested * 100).round(2)
  end

  def calculate_success_rate(investments)
    return 0 if investments.empty?
    
    successful_count = investments.select { |inv| inv.project.successful? }.count
    (successful_count.to_f / investments.count * 100).round(2)
  end

  def generate_performance_data
    # Generate monthly performance data for charts
    months = 12.times.map { |i| i.months.ago.beginning_of_month }
    
    months.map do |month|
      {
        month: month.strftime('%b %Y'),
        invested: current_user.investments.where(created_at: month..month.end_of_month).sum(:amount),
        returns: current_user.investments.where(created_at: month..month.end_of_month).sum(:returns_amount)
      }
    end.reverse
  end

  def generate_investment_timeline
    current_user.investments.group_by_month(:created_at, last: 12)
                           .sum(:amount)
  end

  def generate_category_distribution
    current_user.investments.joins(:project)
                           .group('projects.category')
                           .sum(:amount)
  end

  def generate_roi_analysis
    current_user.investments.joins(:project)
                           .where(projects: { status: 'completed' })
                           .group('projects.category')
                           .average('(investments.returns_amount - investments.amount) / investments.amount * 100')
  end

  def generate_risk_assessment
    # Simple risk assessment based on project categories and success rates
    categories = current_user.investments.joins(:project).distinct.pluck('projects.category')
    
    categories.map do |category|
      investments_in_category = current_user.investments.joins(:project)
                                          .where(projects: { category: category })
      
      success_rate = calculate_success_rate(investments_in_category)
      risk_level = case success_rate
                  when 0..30 then 'High'
                  when 31..60 then 'Medium'
                  else 'Low'
                  end
      
      {
        category: category,
        success_rate: success_rate,
        risk_level: risk_level,
        total_invested: investments_in_category.sum(:amount)
      }
    end
  end

  def calculate_user_rank(user)
    total_invested = user.investments.sum(:amount)
    User.joins(:investments)
        .where(role: 'investor')
        .group('users.id')
        .having('SUM(investments.amount) > ?', total_invested)
        .count + 1
  end

  def investment_params
    params.require(:investment).permit(:amount, :payment_method, :notes)
  end
end

