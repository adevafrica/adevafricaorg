class ProjectsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_project, only: [:show, :edit, :update, :destroy, :vote, :invest, :follow, :unfollow]
  before_action :check_project_owner, only: [:edit, :update, :destroy]

  def index
    @projects = filter_and_sort_projects
    @categories = get_project_categories
    @funding_stages = get_funding_stages
    @featured_projects = Project.featured.active.limit(3) rescue Project.published.limit(3)
    @stats = {
      total_projects: Project.published.count,
      total_funding: calculate_total_funding,
      success_rate: calculate_success_rate
    }

    respond_to do |format|
      format.html
      format.json { render json: @projects }
    end
  end

  def show
    @investment = Investment.new
    @vote = Vote.new
    @recent_updates = @project.project_updates.recent.limit(5)
    @team_members = @project.team.team_memberships.includes(:user) if @project.team
    
    # Enhanced show page data
    @similar_projects = find_similar_projects
    @investment_summary = calculate_investment_summary
    @social_proof = calculate_social_proof
    @can_vote = current_user && can_user_vote?
    @can_invest = current_user&.investor? && @project.can_receive_funding?
    @user_vote = current_user ? @project.votes.find_by(user: current_user) : nil
    @user_investment = current_user ? @project.investments.find_by(user: current_user) : nil

    # Increment view count if method exists
    @project.increment!(:view_count) if @project.respond_to?(:view_count)

    respond_to do |format|
      format.html
      format.json { render json: project_json }
    end
  end

  def new
    @project = current_user.projects.build if current_user.respond_to?(:projects)
    @project ||= Project.new
    @categories = get_project_categories
    @funding_stages = get_funding_stages
  end

  def create
    if current_user.respond_to?(:projects)
      @project = current_user.projects.build(project_params)
    else
      @project = Project.new(project_params.merge(user: current_user))
    end
    
    @project.team = current_user.teams.first if current_user.respond_to?(:teams) && current_user.teams.any?

    if @project.save
      redirect_to @project, notice: 'Project was successfully created.'
    else
      @categories = get_project_categories
      @funding_stages = get_funding_stages
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @categories = get_project_categories
    @funding_stages = get_funding_stages
  end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: 'Project was successfully updated.'
    else
      @categories = get_project_categories
      @funding_stages = get_funding_stages
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_path, notice: 'Project was successfully deleted.'
  end

  def vote
    authorize @project if respond_to?(:authorize)
    
    @vote = @project.votes.build(vote_params)
    @vote.user = current_user

    if @vote.save
      respond_to do |format|
        format.html { redirect_to @project, notice: 'Your vote has been recorded!' }
        format.json { 
          render json: { 
            success: true, 
            message: 'Vote recorded successfully!',
            vote_count: @project.total_votes,
            vote_score: (@project.respond_to?(:vote_score) ? @project.vote_score : @project.positive_votes - @project.negative_votes)
          }
        }
      end
    else
      respond_to do |format|
        format.html { redirect_to @project, alert: 'Unable to record your vote. Please try again.' }
        format.json { 
          render json: { 
            success: false, 
            message: @vote.errors.full_messages.join(', ')
          }
        }
      end
    end
  end

  def invest
    return redirect_to new_user_session_path unless user_signed_in?
    return redirect_to @project, alert: 'Investment not available for this project.' unless @project.can_receive_funding?
    return redirect_to @project, alert: 'Only investors can invest in projects.' unless current_user.investor?

    @investment = @project.investments.build(
      user: current_user,
      amount: params[:amount],
      investment_type: params[:investment_type] || 'equity'
    )

    if @investment.save
      redirect_to @project, notice: 'Investment submitted successfully!'
    else
      redirect_to @project, alert: @investment.errors.full_messages.join(', ')
    end
  end

  def follow
    return redirect_to new_user_session_path unless user_signed_in?
    redirect_to @project, notice: 'You are now following this project!'
  end

  def unfollow
    return redirect_to new_user_session_path unless user_signed_in?
    redirect_to @project, notice: 'You are no longer following this project.'
  end

  def my_projects
    if current_user.respond_to?(:projects)
      @projects = current_user.projects.includes(:team, :votes, :investments)
      @draft_projects = @projects.where(status: 'draft')
      @active_projects = @projects.where(status: ['published', 'funded', 'approved'])
      @completed_projects = @projects.where(status: 'completed')
    else
      @projects = []
      @draft_projects = []
      @active_projects = []
      @completed_projects = []
    end
  end

  def analytics
    @project = current_user.projects.find(params[:id]) if current_user.respond_to?(:projects)
    @project ||= Project.find(params[:id])
    
    return redirect_to projects_path, alert: 'Unauthorized' unless can_access_analytics?
    
    @analytics_data = {
      views: @project.respond_to?(:view_count) ? (@project.view_count || 0) : 0,
      votes: @project.total_votes,
      investments: @project.investments.count,
      funding_progress: @project.funding_percentage,
      conversion_rate: calculate_conversion_rate(@project)
    }
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def check_project_owner
    project_owner = @project.user if @project.respond_to?(:user)
    project_owner ||= @project.team&.leader if @project.team.respond_to?(:leader)
    
    unless project_owner == current_user || current_user.admin?
      redirect_to @project, alert: 'You are not authorized to perform this action.'
    end
  end

  def project_params
    params.require(:project).permit(
      :title, :short_description, :description, :category, :funding_stage,
      :funding_goal, :funding_deadline, :github_url, :demo_url, :website_url,
      :tech_stack, :projected_revenue, :featured_image, :pitch_video, :pitch_deck,
      images: [], screenshots: [], documents: []
    )
  end

  def vote_params
    params.require(:vote).permit(:vote_type, :comment, :rating)
  end

  def filter_and_sort_projects
    projects = Project.published.includes(:team, :investments, :votes)

    # Apply filters
    projects = projects.where(category: params[:category]) if params[:category].present?
    projects = projects.where('title ILIKE ? OR description ILIKE ?', "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?

    # Apply sorting
    case params[:sort]
    when 'recent'
      projects = projects.order(created_at: :desc)
    when 'popular'
      projects = projects.order('votes_count DESC, view_count DESC')
    when 'funding'
      projects = projects.order(funding_goal: :desc)
    when 'trending'
      projects = projects.where('created_at > ?', 30.days.ago).order('votes_count DESC')
    else
      projects = projects.where(featured: true).or(projects.order(created_at: :desc))
    end

    projects.page(params[:page]).per(12)
  end

  def get_project_categories
    if Project.respond_to?(:category) && Project.category.respond_to?(:options)
      Project.category.options
    else
      [['Technology', 'technology'], ['Agriculture', 'agriculture'], ['Healthcare', 'healthcare'], ['Education', 'education'], ['FinTech', 'fintech']]
    end
  end

  def get_funding_stages
    if Project.respond_to?(:funding_stage) && Project.funding_stage.respond_to?(:options)
      Project.funding_stage.options
    else
      [['Idea', 'idea'], ['Prototype', 'prototype'], ['MVP', 'mvp'], ['Early Stage', 'early_stage'], ['Growth Stage', 'growth_stage']]
    end
  end

  def calculate_total_funding
    Investment.where(status: 'confirmed').sum(:amount) rescue 0
  end

  def calculate_success_rate
    total_projects = Project.where.not(status: 'draft').count
    return 0 if total_projects.zero?
    
    successful_projects = Project.where(status: ['completed', 'funded']).count
    (successful_projects.to_f / total_projects * 100).round(2)
  end

  def find_similar_projects
    Project.published
           .where(category: @project.category)
           .where.not(id: @project.id)
           .limit(4)
  end

  def calculate_investment_summary
    {
      total_raised: @project.total_raised,
      investors_count: @project.investments.count,
      funding_percentage: @project.funding_percentage,
      days_remaining: @project.days_remaining,
      average_investment: @project.investments.any? ? (@project.total_raised / @project.investments.count).round(2) : 0
    }
  end

  def calculate_social_proof
    {
      votes: @project.total_votes,
      rating: @project.respond_to?(:average_rating) ? @project.average_rating : 0,
      views: @project.respond_to?(:view_count) ? (@project.view_count || 0) : 0,
      followers: 0,
      github_stars: 0
    }
  end

  def can_user_vote?
    return false if @project.user == current_user
    return false if @project.team&.leader == current_user
    !@project.votes.exists?(user: current_user)
  end

  def can_access_analytics?
    return true if current_user.admin?
    return true if @project.user == current_user
    return true if @project.team&.leader == current_user
    false
  end

  def calculate_conversion_rate(project)
    views = project.respond_to?(:view_count) ? project.view_count : 0
    return 0 if views.nil? || views.zero?
    
    conversions = project.investments.count + project.votes.count
    (conversions.to_f / views * 100).round(2)
  end

  def project_json
    team_members_data = []
    if @project.team && @project.team.respond_to?(:team_memberships)
      team_members_data = @project.team.team_memberships.includes(:user).map do |membership|
        user = membership.user
        {
          name: user.full_name,
          role: user.role,
          avatar: user.avatar.attached? ? url_for(user.avatar) : nil
        }
      end
    end

    {
      id: @project.id,
      title: @project.title,
      description: @project.description,
      category: @project.category,
      funding_goal: @project.funding_goal,
      current_funding: @project.total_raised,
      funding_percentage: @project.funding_percentage,
      days_remaining: @project.days_remaining,
      vote_count: @project.total_votes,
      team_members: team_members_data,
      tech_stack: @project.respond_to?(:tech_stack_array) ? @project.tech_stack_array : [],
      social_proof: calculate_social_proof
    }
  end
end

