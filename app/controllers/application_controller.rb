class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :current_user

  protected

  # 현재 로그인한 사용자 반환
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  helper_method :current_user

  # 로그인 상태 확인
  def user_signed_in?
    current_user.present?
  end
  helper_method :user_signed_in?

  # 로그인 필수
  def require_authentication
    unless user_signed_in?
      store_location
      redirect_to login_path, alert: '로그인이 필요합니다.'
    end
  end

  # 현재 위치 저장 (로그인 후 돌아오기 위해)
  def store_location
    session[:return_to] = request.original_url if request.get? && !request.xhr?
  end

  # 관리자 권한 필수
  def require_admin
    unless user_signed_in? && current_user.admin?
      redirect_to root_path, alert: '관리자 권한이 필요합니다.'
    end
  end

  # 사용자 로그인 처리
  def login(user)
    session[:user_id] = user.id
    @current_user = user
  end

  # 로그아웃 처리
  def logout
    session[:user_id] = nil
    @current_user = nil
  end
end
