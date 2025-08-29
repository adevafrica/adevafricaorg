class Resource < ApplicationRecord
  validates :title, :description, :resource_type, presence: true
  validates :resource_type, inclusion: { in: %w[guide template tool article video] }
  validates :access_level, inclusion: { in: %w[public member premium] }

  enum resource_type: { guide: 0, template: 1, tool: 2, article: 3, video: 4 }
  enum access_level: { public: 0, member: 1, premium: 2 }

  has_one_attached :file
  has_one_attached :thumbnail

  scope :available, -> { where(published: true) }
  scope :by_type, ->(type) { where(resource_type: type) }
  scope :by_access, ->(level) { where(access_level: level) }
  scope :recent, -> { order(created_at: :desc) }

  def accessible_by?(user)
    return true if public?
    return false unless user
    
    case access_level
    when 'member'
      true
    when 'premium'
      user.investor? || user.admin?
    else
      false
    end
  end

  def file_size_human
    return nil unless file.attached?
    
    size = file.byte_size
    units = %w[B KB MB GB TB]
    
    return "#{size} #{units[0]}" if size < 1024
    
    size = size.to_f
    i = 0
    while size >= 1024 && i < units.length - 1
      size /= 1024.0
      i += 1
    end
    
    "#{size.round(1)} #{units[i]}"
  end
end

