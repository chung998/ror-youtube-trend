class User < ApplicationRecord
  has_secure_password
  
  has_many :trending_videos, dependent: :nullify
  
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
  
  # 관리자 여부 확인
  def admin?
    admin
  end
  
  # 인증된 사용자 여부 확인
  def verified?
    verified
  end
  
  # 로그인 시간 업데이트
  def update_last_sign_in!
    update_column(:last_sign_in_at, Time.current)
  end
end
