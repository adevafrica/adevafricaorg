class ProjectsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]
  before_action :set_project, only: [:show, :vote]

  def index
    @projects = Project.published
                      .includes(:team, :investments, :votes)
                      .page(params[:page])
                      .per(12)
    
    # Filter by category if provided
    @projects = @projects.where(category: params[:category]) if params[:category].present?
    
    # Search functionality
    @projects = @projects.where("title ILIKE ? OR description ILIKE ?", 
                               "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
  end

  def show
    @investment = Investment.new
    @vote = Vote.new
    @recent_updates = @project.project_updates.recent.limit(5)
    @team_members = @project.team.team_memberships.includes(:user)
  end

  def vote
    authorize @project
    
    @vote = @project.votes.build(vote_params)
    @vote.user = current_user

    if @vote.save
      redirect_to @project, notice: 'Your vote has been recorded!'
    else
      redirect_to @project, alert: 'Unable to record your vote. Please try again.'
    end
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def vote_params
    params.require(:vote).permit(:vote_type, :comment)
  end
end

