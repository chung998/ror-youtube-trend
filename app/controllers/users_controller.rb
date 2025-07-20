class UsersController < ApplicationController
  before_action :require_authentication, only: [:show]

  # 회원가입 폼
  def new
    # 이미 로그인된 사용자는 홈으로 리다이렉트
    redirect_to root_path if user_signed_in?
    
    @user = User.new
  end

  # 회원가입 처리
  def create
    @user = User.new(user_params)
    
    # 첫 번째 사용자는 자동으로 관리자로 설정
    @user.role = 'admin' if User.count == 0
    
    if @user.save
      login(@user)
      redirect_to root_path, notice: "#{@user.display_name}님, 회원가입을 환영합니다!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # 사용자 프로필
  def show
    @user = current_user
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
