class SessionsController < ApplicationController
  # 로그인 폼
  def new
    # 이미 로그인된 사용자는 홈으로 리다이렉트
    redirect_to root_path if user_signed_in?
  end

  # 로그인 처리
  def create
    user = User.find_by(email: params[:email]&.downcase)
    
    if user&.authenticate(params[:password]) && user.active?
      user.record_login! # 로그인 시간 기록
      login(user)
      
      # 로그인 후 원래 가려던 페이지로 리다이렉트 (없으면 홈으로)
      redirect_url = session[:return_to] || root_path
      session[:return_to] = nil
      
      redirect_to redirect_url, notice: "#{user.display_name}님, 환영합니다!"
    elsif user && !user.active?
      flash.now[:alert] = '계정이 비활성화되었습니다. 관리자에게 문의하세요.'
      render :new, status: :unprocessable_entity
    else
      flash.now[:alert] = '이메일 또는 비밀번호가 잘못되었습니다.'
      render :new, status: :unprocessable_entity
    end
  end

  # 로그아웃 처리
  def destroy
    user_name = current_user&.display_name
    logout
    redirect_to root_path, notice: "#{user_name}님, 로그아웃되었습니다."
  end
end
