class Admin::DashboardController < ApplicationController
  before_action :ensure_admin
  
  def index
    @collection_stats = build_collection_stats
    @recent_logs = CollectionLog.order(created_at: :desc).limit(20)
    @failed_collections = CollectionLog.recent_failures
    @next_scheduled = CollectionLog.next_scheduled_time
  end
  
  def collection_logs
    @logs = CollectionLog.order(created_at: :desc).limit(100)
    
    # 지역별 필터링
    if params[:region].present?
      @logs = @logs.where(region_code: params[:region].upcase)
    end
    
    # 상태별 필터링
    if params[:status].present?
      @logs = @logs.where(status: params[:status])
    end
  end
  
  private
  
  def ensure_admin
    # TODO: 실제 인증 시스템 구현 후 활성화
    # redirect_to root_path unless user_signed_in? && current_user.admin?
  end
  
  def build_collection_stats
    {
      today_collections: CollectionLog.today.count,
      successful_today: CollectionLog.today.completed.count,
      failed_today: CollectionLog.today.failed.count,
      total_videos: TrendingVideo.recent.count,
      api_calls_today: CollectionLog.today.sum(:api_calls_used)
    }
  end
end
