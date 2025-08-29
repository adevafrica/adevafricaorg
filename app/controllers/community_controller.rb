class CommunityController < ApplicationController
  before_action :authenticate_user!, except: [:index, :forums, :show_forum, :show_topic]

  def index
    @recent_topics = ForumTopic.includes(:user, :forum, :posts).recent.limit(5)
    @active_forums = Forum.active.includes(:topics).limit(6)
    @upcoming_events = Event.upcoming.limit(3)
    @community_stats = {
      total_members: User.count,
      active_discussions: ForumTopic.active.count,
      total_posts: ForumPost.count,
      upcoming_events: Event.upcoming.count
    }
  end

  def forums
    @forums = Forum.includes(:topics, :posts).order(:position, :name)
  end

  def show_forum
    @forum = Forum.find(params[:id])
    @topics = @forum.topics.includes(:user, :last_post_user)
                          .page(params[:page]).per(20)
    
    if params[:search].present?
      @topics = @topics.where("title ILIKE ? OR content ILIKE ?", 
                             "%#{params[:search]}%", "%#{params[:search]}%")
    end
  end

  def show_topic
    @topic = ForumTopic.find(params[:id])
    @forum = @topic.forum
    @posts = @topic.posts.includes(:user).page(params[:page]).per(10)
    @new_post = ForumPost.new
    
    # Mark topic as read for current user
    if user_signed_in?
      @topic.mark_as_read_for(current_user)
    end
  end

  def new_topic
    @forum = Forum.find(params[:forum_id])
    @topic = @forum.topics.build
  end

  def create_topic
    @forum = Forum.find(params[:forum_id])
    @topic = @forum.topics.build(topic_params)
    @topic.user = current_user

    if @topic.save
      redirect_to community_topic_path(@topic), notice: 'Topic created successfully.'
    else
      render :new_topic
    end
  end

  def create_post
    @topic = ForumTopic.find(params[:topic_id])
    @post = @topic.posts.build(post_params)
    @post.user = current_user

    if @post.save
      @topic.update_last_post_info(@post)
      redirect_to community_topic_path(@topic), notice: 'Post added successfully.'
    else
      @posts = @topic.posts.includes(:user).page(params[:page]).per(10)
      render :show_topic
    end
  end

  def polls
    @polls = Poll.includes(:user, :poll_options).active.page(params[:page]).per(10)
  end

  def show_poll
    @poll = Poll.find(params[:id])
    @user_vote = current_user&.poll_votes&.find_by(poll: @poll)
  end

  def vote_poll
    @poll = Poll.find(params[:id])
    @poll_option = @poll.poll_options.find(params[:poll_option_id])
    
    # Check if user already voted
    existing_vote = current_user.poll_votes.find_by(poll: @poll)
    
    if existing_vote
      redirect_to community_poll_path(@poll), alert: 'You have already voted on this poll.'
      return
    end

    vote = current_user.poll_votes.build(
      poll: @poll,
      poll_option: @poll_option
    )

    if vote.save
      redirect_to community_poll_path(@poll), notice: 'Your vote has been recorded.'
    else
      redirect_to community_poll_path(@poll), alert: 'Unable to record your vote.'
    end
  end

  def hackathons
    @hackathons = Hackathon.includes(:participants, :projects).order(:start_date)
    
    case params[:filter]
    when 'upcoming'
      @hackathons = @hackathons.upcoming
    when 'ongoing'
      @hackathons = @hackathons.ongoing
    when 'completed'
      @hackathons = @hackathons.completed
    else
      @hackathons = @hackathons.active
    end
    
    @hackathons = @hackathons.page(params[:page]).per(12)
  end

  def show_hackathon
    @hackathon = Hackathon.find(params[:id])
    @participants = @hackathon.participants.includes(:user).limit(20)
    @projects = @hackathon.projects.includes(:team, :votes).limit(12)
    @user_participation = current_user&.hackathon_participants&.find_by(hackathon: @hackathon)
  end

  def join_hackathon
    @hackathon = Hackathon.find(params[:id])
    
    unless @hackathon.registration_open?
      redirect_to community_hackathon_path(@hackathon), alert: 'Registration is not open for this hackathon.'
      return
    end

    if @hackathon.participants.where(user: current_user).exists?
      redirect_to community_hackathon_path(@hackathon), alert: 'You are already registered for this hackathon.'
      return
    end

    participation = @hackathon.participants.build(
      user: current_user,
      status: 'registered'
    )

    if participation.save
      HackathonMailer.registration_confirmation(@hackathon, current_user).deliver_later
      redirect_to community_hackathon_path(@hackathon), notice: 'Successfully registered for the hackathon!'
    else
      redirect_to community_hackathon_path(@hackathon), alert: 'Unable to register for the hackathon.'
    end
  end

  def talent_showcase
    @showcases = TalentShowcase.includes(:user, :skills).published
                              .page(params[:page]).per(12)
    
    if params[:skill].present?
      @showcases = @showcases.joins(:skills).where(skills: { name: params[:skill] })
    end
    
    if params[:location].present?
      @showcases = @showcases.joins(:user).where(users: { country: params[:location] })
    end
    
    @featured_skills = Skill.joins(:talent_showcases).group(:name).order('COUNT(*) DESC').limit(20)
  end

  def show_talent
    @showcase = TalentShowcase.find(params[:id])
    @user = @showcase.user
    @related_showcases = TalentShowcase.where.not(id: @showcase.id)
                                      .joins(:skills)
                                      .where(skills: { id: @showcase.skill_ids })
                                      .limit(4)
  end

  private

  def topic_params
    params.require(:forum_topic).permit(:title, :content, :pinned, :locked)
  end

  def post_params
    params.require(:forum_post).permit(:content)
  end
end

