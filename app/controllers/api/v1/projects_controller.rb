class Api::V1::ProjectsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]
  before_action :set_project, only: [:show, :investments, :votes]

  def index
    @projects = Project.published
                      .includes(:team, :investments, :votes, :map_locations)
                      .page(params[:page])
                      .per(params[:per_page] || 20)

    # Apply filters
    @projects = @projects.where(category: params[:category]) if params[:category].present?
    @projects = @projects.where("title ILIKE ? OR description ILIKE ?", 
                               "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?

    render json: {
      projects: ActiveModelSerializers::SerializableResource.new(@projects),
      meta: {
        current_page: @projects.current_page,
        total_pages: @projects.total_pages,
        total_count: @projects.total_count,
        per_page: @projects.limit_value
      }
    }
  end

  def show
    render json: {
      project: ActiveModelSerializers::SerializableResource.new(@project, include: ['team', 'investments', 'votes']),
      stats: {
        funding_percentage: @project.funding_percentage,
        total_raised: @project.total_raised,
        days_remaining: @project.days_remaining,
        total_votes: @project.total_votes,
        vote_score: @project.vote_score
      }
    }
  end

  def create
    authorize Project
    
    @project = current_user.teams.first&.projects&.build(project_params)
    
    if @project&.save
      render json: { project: ActiveModelSerializers::SerializableResource.new(@project) }, status: :created
    else
      render json: { errors: @project&.errors || ['No team found'] }, status: :unprocessable_entity
    end
  end

  def investments
    authorize @project
    
    @investment = @project.investments.build(investment_params)
    @investment.user = current_user

    if @investment.save
      # Process payment through StripeService
      payment_result = StripeService.new.create_checkout_session(@investment)
      
      if payment_result[:success]
        render json: { 
          investment: ActiveModelSerializers::SerializableResource.new(@investment),
          checkout_url: payment_result[:checkout_url]
        }, status: :created
      else
        @investment.destroy
        render json: { errors: payment_result[:errors] }, status: :unprocessable_entity
      end
    else
      render json: { errors: @investment.errors }, status: :unprocessable_entity
    end
  end

  def votes
    authorize @project
    
    @vote = @project.votes.build(vote_params)
    @vote.user = current_user

    if @vote.save
      render json: { 
        vote: ActiveModelSerializers::SerializableResource.new(@vote),
        project_stats: {
          total_votes: @project.total_votes,
          positive_votes: @project.positive_votes,
          negative_votes: @project.negative_votes,
          vote_score: @project.vote_score
        }
      }, status: :created
    else
      render json: { errors: @vote.errors }, status: :unprocessable_entity
    end
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:title, :description, :category, :funding_goal, :funding_deadline, :featured_image)
  end

  def investment_params
    params.require(:investment).permit(:amount, :payment_method)
  end

  def vote_params
    params.require(:vote).permit(:vote_type, :comment)
  end
end

