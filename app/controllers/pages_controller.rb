class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home, :about, :contact, :privacy, :terms, :cookies, :projects, :community, :resources, :events, :blog, :careers]

  def home
    @featured_projects = Project.featured.active.limit(6)
    @recent_projects = Project.active.recent.limit(8)
    @trending_projects = Project.trending.limit(4)
    @stats = {
      total_projects: Project.active.count,
      total_users: User.active.count,
      total_funding: calculate_total_funding,
      success_stories: Project.completed.count
    }
    @testimonials = load_testimonials
    @blog_posts = load_recent_blog_posts
  end

  def about
    @team_members = load_team_members
    @company_stats = {
      founded_year: 2024,
      team_size: User.where.not(role: 'member').count,
      projects_launched: Project.completed.count,
      countries_served: 15
    }
    @values = load_company_values
    @timeline = load_company_timeline
  end

  def teams
    @departments = load_departments
    @team_members = User.active.where.not(role: 'member')
    @skills_cloud = load_skills_cloud
  end

  def projects
    @categories = Project.category.options rescue []
    @funding_stages = Project.funding_stage.options rescue []
    @projects = filter_projects
    @featured_projects = Project.featured.active.limit(3)
    @stats = {
      total_projects: Project.active.count,
      total_funding: calculate_total_funding,
      success_rate: calculate_success_rate
    }
  end

  def investors
    redirect_to new_user_session_path unless user_signed_in?
    return unless current_user&.investor? || current_user&.admin?

    @investment_opportunities = Project.active.limit(10)
    @portfolio = current_user.investments if current_user.respond_to?(:investments)
    @investment_stats = current_user.investor_profile if current_user.respond_to?(:investor_profile)
    @trending_categories = trending_investment_categories
  end

  def community
    @forum_categories = load_forum_categories
    @recent_posts = load_recent_forum_posts
    @popular_posts = load_popular_forum_posts
    @community_stats = {
      total_posts: 0,
      active_members: User.active.count,
      categories: 5
    }
  end

  def resources
    @categories = resource_categories
    @featured_resources = load_featured_resources
    @recent_resources = load_recent_resources
    @popular_downloads = load_popular_downloads
  end

  def events
    @upcoming_events = load_upcoming_events
    @past_events = load_past_events
    @hackathons = load_hackathons
    @webinars = load_webinars
  end

  def blog
    @featured_post = load_featured_blog_post
    @recent_posts = load_recent_blog_posts
    @categories = blog_categories
    @popular_tags = blog_tags
  end

  def careers
    @open_positions = load_open_positions
    @company_culture = load_company_culture
    @benefits = load_benefits
    @application_process = load_application_process
  end

  def contact
    @contact_info = {
      email: 'hello@adevafrica.com',
      phone: '+254 700 000 000',
      address: 'Nairobi, Kenya',
      social_media: {
        twitter: '@adevafrica',
        linkedin: 'adevafrica',
        github: 'adevafrica'
      }
    }
  end

  def privacy
    @last_updated = '2024-08-30'
  end

  def terms
    @last_updated = '2024-08-30'
  end

  def cookies
    @last_updated = '2024-08-30'
  end

  def dashboard
    redirect_to new_user_session_path unless user_signed_in?
    
    case current_user.role
    when 'investor'
      redirect_to investors_path
    when 'admin'
      redirect_to admin_dashboard_path
    when 'mentor'
      redirect_to mentor_dashboard_path
    else
      @user_projects = current_user.projects.recent.limit(5) if current_user.respond_to?(:projects)
      @recent_activities = load_user_activities
      @notifications = load_user_notifications
      @recommended_projects = load_recommended_projects
      @skill_recommendations = load_skill_recommendations
    end
  end

  private

  def filter_projects
    projects = Project.active
    
    projects = projects.where(category: params[:category]) if params[:category].present?
    projects = projects.where('title ILIKE ? OR description ILIKE ?', "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
    
    case params[:sort]
    when 'recent'
      projects.recent
    when 'popular'
      projects.order(:vote_count)
    when 'funding'
      projects.order(funding_goal: :desc)
    else
      projects.featured.or(projects.recent)
    end.limit(20)
  end

  def calculate_total_funding
    Investment.confirmed.sum(:amount) rescue 0
  end

  def load_testimonials
    [
      {
        name: "Amara Okafor",
        role: "Founder, HealthTech Solutions",
        content: "DevAfrica helped us connect with the right investors and mentors. Our telemedicine platform now serves over 10,000 patients across Nigeria.",
        avatar: "testimonial1.jpg"
      },
      {
        name: "Kwame Asante",
        role: "CTO, AgriSmart",
        content: "The community support and technical expertise we found on DevAfrica was instrumental in scaling our agricultural IoT solution.",
        avatar: "testimonial2.jpg"
      }
    ]
  end

  def load_recent_blog_posts
    [
      {
        title: "The Future of African Tech Innovation",
        excerpt: "Exploring emerging trends and opportunities in Africa's technology landscape.",
        published_at: 2.days.ago,
        category: "Innovation",
        slug: "future-of-african-tech"
      },
      {
        title: "Building Sustainable Startups in Africa",
        excerpt: "Key strategies for creating lasting impact while building profitable businesses.",
        published_at: 5.days.ago,
        category: "Business",
        slug: "sustainable-startups-africa"
      }
    ]
  end

  def load_team_members
    User.where(role: [:admin, :mentor, :partner])
        .active
        .limit(12)
  end

  def load_departments
    {
      'Engineering' => {
        description: 'Building the future of African technology',
        members: User.developer.active.count,
        skills: ['Ruby on Rails', 'React', 'Python', 'DevOps']
      },
      'Design' => {
        description: 'Creating beautiful and intuitive user experiences',
        members: User.designer.active.count,
        skills: ['UI/UX Design', 'Figma', 'Adobe Creative Suite', 'Prototyping']
      },
      'Business Development' => {
        description: 'Connecting innovators with opportunities',
        members: User.partner.active.count,
        skills: ['Strategy', 'Partnerships', 'Market Analysis', 'Sales']
      },
      'Mentorship' => {
        description: 'Guiding the next generation of African innovators',
        members: User.mentor.active.count,
        skills: ['Leadership', 'Coaching', 'Industry Expertise', 'Network Building']
      }
    }
  end

  def load_skills_cloud
    ['Ruby on Rails', 'React', 'Python', 'JavaScript', 'UI/UX Design', 'Mobile Development', 'AI/ML', 'Blockchain', 'DevOps', 'Data Science']
  end

  def load_company_values
    [
      {
        title: "Innovation First",
        description: "We believe in the power of African innovation to solve global challenges.",
        icon: "lightbulb"
      },
      {
        title: "Community Driven",
        description: "Our strength comes from our diverse and collaborative community.",
        icon: "users"
      },
      {
        title: "Sustainable Impact",
        description: "We focus on creating lasting positive change across the continent.",
        icon: "globe"
      },
      {
        title: "Excellence",
        description: "We strive for excellence in everything we do, from code to community.",
        icon: "star"
      }
    ]
  end

  def load_company_timeline
    [
      { year: 2024, event: "DevAfrica founded with vision to transform African tech ecosystem" },
      { year: 2024, event: "Launched platform with first 100 innovators and 10 projects" },
      { year: 2024, event: "First successful funding round completed - $50K raised" },
      { year: 2024, event: "Expanded to 5 African countries with local partnerships" }
    ]
  end

  def calculate_success_rate
    total_projects = Project.where.not(status: :draft).count
    return 0 if total_projects.zero?
    
    successful_projects = Project.where(status: [:completed, :funded]).count
    (successful_projects.to_f / total_projects * 100).round(2)
  end

  def trending_investment_categories
    ['Technology', 'FinTech', 'HealthTech', 'AgriTech', 'EdTech']
  end

  def resource_categories
    ['APIs & SDKs', 'Templates', 'Guides', 'Research Papers', 'Tools', 'Datasets']
  end

  def load_featured_resources
    []
  end

  def load_recent_resources
    []
  end

  def load_popular_downloads
    []
  end

  def load_upcoming_events
    []
  end

  def load_past_events
    []
  end

  def load_hackathons
    []
  end

  def load_webinars
    []
  end

  def load_featured_blog_post
    load_recent_blog_posts.first
  end

  def blog_categories
    ['Innovation', 'Business', 'Technology', 'Funding', 'Community']
  end

  def blog_tags
    ['startup', 'funding', 'africa', 'innovation', 'technology', 'business']
  end

  def load_open_positions
    []
  end

  def load_company_culture
    []
  end

  def load_benefits
    []
  end

  def load_application_process
    []
  end

  def load_user_activities
    []
  end

  def load_user_notifications
    []
  end

  def load_recommended_projects
    Project.active.limit(5)
  end

  def load_skill_recommendations
    []
  end

  def load_forum_categories
    []
  end

  def load_recent_forum_posts
    []
  end

  def load_popular_forum_posts
    []
  end
end

