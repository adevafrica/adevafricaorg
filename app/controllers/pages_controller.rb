class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home, :about, :contact]

  def home
    @featured_projects = Project.featured.limit(6)
    @recent_projects = Project.recent.limit(8)
  end

  def about
  end

  def contact
  end
end

