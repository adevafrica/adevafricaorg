class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :team_memberships, dependent: :destroy
  has_many :teams, through: :team_memberships
  has_many :investments, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :pool_contributions, dependent: :destroy
  
  has_one_attached :avatar

  validates :first_name, :last_name, presence: true
  validates :role, inclusion: { in: %w[member investor admin] }

  enum role: { member: 0, investor: 1, admin: 2 }

  scope :active, -> { where(active: true) }

  def full_name
    "#{first_name} #{last_name}"
  end

  def display_name
    full_name.present? ? full_name : email
  end

  def admin?
    role == 'admin'
  end

  def investor?
    role == 'investor'
  end

  def member?
    role == 'member'
  end

  def total_investments
    investments.sum(:amount)
  end

  def total_votes
    votes.count
  end
end

