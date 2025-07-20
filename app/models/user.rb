class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, 
                   uniqueness: { case_sensitive: false },
                   format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :role, inclusion: { in: %w[user admin] }
  validates :status, inclusion: { in: %w[active inactive suspended] }

  before_save { self.email = email.downcase }

  # 스코프들
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
  scope :suspended, -> { where(status: 'suspended') }
  scope :admins, -> { where(role: 'admin') }
  scope :regular_users, -> { where(role: 'user') }
  scope :recent_login, -> { where('last_login_at > ?', 30.days.ago) }
  scope :search_by_name_or_email, ->(query) {
    where('name ILIKE ? OR email ILIKE ?', "%#{query}%", "%#{query}%")
  }

  # 관리자 권한 확인
  def admin?
    role == 'admin'
  end

  # 계정 상태 확인
  def active?
    status == 'active'
  end

  def inactive?
    status == 'inactive'
  end

  def suspended?
    status == 'suspended'
  end

  # 사용자 표시명
  def display_name
    name.present? ? name : email.split('@').first
  end

  # 계정 상태 변경
  def activate!
    update!(status: 'active')
  end

  def deactivate!
    update!(status: 'inactive')
  end

  def suspend!
    update!(status: 'suspended')
  end

  # 권한 변경
  def promote_to_admin!
    update!(role: 'admin')
  end

  def demote_to_user!
    update!(role: 'user')
  end

  # 로그인 기록 업데이트
  def record_login!
    update_column(:last_login_at, Time.current)
  end

  # 상태 한글 표시
  def status_korean
    case status
    when 'active'
      '활성'
    when 'inactive'  
      '비활성'
    when 'suspended'
      '정지'
    else
      '알 수 없음'
    end
  end

  # 가입 후 경과일
  def days_since_signup
    (Date.current - created_at.to_date).to_i
  end

  # 최근 로그인 여부
  def recently_logged_in?
    last_login_at.present? && last_login_at > 30.days.ago
  end
end
