class Admin::UsersController < ApplicationController
  before_action :require_admin
  before_action :set_user, only: [:show, :edit, :update, :destroy, :toggle_role, :toggle_status]

  def index
    @users = User.order(created_at: :desc)

    # 검색 기능
    if params[:search].present?
      @users = @users.search_by_name_or_email(params[:search])
    end

    # 필터링
    case params[:filter]
    when 'admins'
      @users = @users.admins
    when 'regular_users'
      @users = @users.regular_users
    when 'active'
      @users = @users.active
    when 'inactive'
      @users = @users.inactive
    when 'suspended'
      @users = @users.suspended
    when 'recent_login'
      @users = @users.recent_login
    end

    # 페이지네이션 (기본 20개씩)
    @users = @users.page(params[:page]).per(20) if defined?(Kaminari)

    # 통계
    @stats = {
      total: User.count,
      admins: User.admins.count,
      active: User.active.count,
      inactive: User.inactive.count,
      suspended: User.suspended.count,
      recent_login: User.recent_login.count
    }
  end

  def show
    # 사용자 상세 정보
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    
    if @user.save
      redirect_to admin_users_path, notice: "사용자 '#{@user.display_name}'이 성공적으로 생성되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # 사용자 편집 폼
  end

  def update
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "사용자 정보가 성공적으로 업데이트되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to admin_users_path, alert: "자신의 계정은 삭제할 수 없습니다."
      return
    end

    @user.destroy
    redirect_to admin_users_path, notice: "사용자 '#{@user.display_name}'이 삭제되었습니다."
  end

  # 권한 토글 (AJAX)
  def toggle_role
    if @user == current_user
      render json: { error: '자신의 권한은 변경할 수 없습니다.' }, status: :unprocessable_entity
      return
    end

    if @user.admin?
      @user.demote_to_user!
      message = "#{@user.display_name}님이 일반사용자로 변경되었습니다."
    else
      @user.promote_to_admin!
      message = "#{@user.display_name}님이 관리자로 변경되었습니다."
    end

    render json: { 
      success: true, 
      message: message,
      new_role: @user.role,
      new_role_korean: @user.admin? ? '관리자' : '일반사용자'
    }
  end

  # 상태 토글 (AJAX)
  def toggle_status
    if @user == current_user
      render json: { error: '자신의 계정 상태는 변경할 수 없습니다.' }, status: :unprocessable_entity
      return
    end

    case @user.status
    when 'active'
      @user.deactivate!
      message = "#{@user.display_name}님의 계정이 비활성화되었습니다."
    when 'inactive'
      @user.activate!
      message = "#{@user.display_name}님의 계정이 활성화되었습니다."
    when 'suspended'
      @user.activate!
      message = "#{@user.display_name}님의 계정 정지가 해제되었습니다."
    end

    render json: { 
      success: true, 
      message: message,
      new_status: @user.status,
      new_status_korean: @user.status_korean
    }
  end

  # 계정 정지 (AJAX)
  def suspend
    @user = User.find(params[:id])
    
    if @user == current_user
      render json: { error: '자신의 계정은 정지할 수 없습니다.' }, status: :unprocessable_entity
      return
    end

    @user.suspend!
    render json: { 
      success: true, 
      message: "#{@user.display_name}님의 계정이 정지되었습니다.",
      new_status: @user.status,
      new_status_korean: @user.status_korean
    }
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role, :status)
  end

  def require_admin
    unless user_signed_in? && current_user.admin?
      redirect_to root_path, alert: '관리자 권한이 필요합니다.'
    end
  end
end 