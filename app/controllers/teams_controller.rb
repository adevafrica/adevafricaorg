class TeamsController < ApplicationController
  before_action :set_team, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!, except: [:index, :show]

  def index
    @teams = Team.includes(:members, :projects).published.page(params[:page])
    @departments = Team.distinct.pluck(:department).compact
    
    if params[:department].present?
      @teams = @teams.where(department: params[:department])
    end
    
    if params[:search].present?
      @teams = @teams.where("name ILIKE ? OR description ILIKE ?", 
                           "%#{params[:search]}%", "%#{params[:search]}%")
    end
  end

  def show
    @team_members = @team.team_memberships.includes(:user).active
    @team_projects = @team.projects.published.limit(6)
    @team_stats = {
      total_projects: @team.projects.count,
      active_projects: @team.projects.active.count,
      total_funding: @team.projects.sum(:total_raised),
      success_rate: @team.calculate_success_rate
    }
  end

  def new
    @team = Team.new
    authorize @team
  end

  def create
    @team = Team.new(team_params)
    @team.creator = current_user
    authorize @team

    if @team.save
      # Add creator as team lead
      @team.team_memberships.create!(
        user: current_user,
        role: 'lead',
        status: 'active'
      )
      
      redirect_to @team, notice: 'Team was successfully created.'
    else
      render :new
    end
  end

  def edit
    authorize @team
  end

  def update
    authorize @team
    
    if @team.update(team_params)
      redirect_to @team, notice: 'Team was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    authorize @team
    @team.destroy
    redirect_to teams_url, notice: 'Team was successfully deleted.'
  end

  def join
    @team = Team.find(params[:id])
    
    if @team.team_memberships.where(user: current_user).exists?
      redirect_to @team, alert: 'You are already a member of this team.'
      return
    end

    membership = @team.team_memberships.build(
      user: current_user,
      role: 'member',
      status: 'pending'
    )

    if membership.save
      # Notify team leads
      TeamMailer.membership_request(@team, current_user).deliver_later
      redirect_to @team, notice: 'Your request to join the team has been sent.'
    else
      redirect_to @team, alert: 'Unable to send join request.'
    end
  end

  private

  def set_team
    @team = Team.find(params[:id])
  end

  def team_params
    params.require(:team).permit(:name, :description, :department, :location, 
                                 :website, :github_url, :linkedin_url, :logo, 
                                 :status, :skills_required, :looking_for_members)
  end
end

