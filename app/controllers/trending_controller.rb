class TrendingController < ApplicationController
  before_action :set_region_and_type, only: [:index, :collect_now]
  
  def index
    @videos = TrendingVideo.cached_trending(@region, @type)
    @last_updated = get_last_updated_time
    @next_collection = CollectionLog.next_scheduled_time
    
    respond_to do |format|
      format.html
      format.json { render json: { videos: @videos, meta: build_meta } }
    end
  end
  
  def search
    @query = params[:q]
    @videos = []
    
    if @query.present?
      # 기본 검색 (전체 텍스트 검색이 구현되면 나중에 업그레이드)
      @videos = TrendingVideo.where(
        "title LIKE ? OR channel_title LIKE ?", 
        "%#{@query}%", "%#{@query}%"
      ).recent.popular.limit(50)
    end
    
    render :index
  end
  
  def collect_now
    # 수동 수집 트리거 (관리자 전용)
    return head :forbidden unless user_signed_in? && current_user.admin?
    
    # TODO: CollectTrendingDataJob이 구현되면 활성화
    # CollectTrendingDataJob.perform_later(@region, @type)
    
    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path, notice: '데이터 수집을 시작했습니다.') }
      format.json { render json: { status: 'started', region: @region } }
    end
  end
  
  private
  
  def set_region_and_type
    @region = params[:region]&.upcase || 'KR'
    @type = params[:type] || 'all'
    
    # 유효하지 않은 지역 코드 처리
    unless %w[KR US JP GB DE FR].include?(@region)
      @region = 'KR'
    end
    
    # 유효하지 않은 타입 처리
    unless %w[all videos shorts].include?(@type)
      @type = 'all'
    end
  end
  
  def get_last_updated_time
    CollectionLog.successful
                 .where(region_code: @region)
                 .order(:completed_at)
                 .last&.completed_at
  end
  
  def build_meta
    {
      region: @region,
      type: @type,
      total_count: @videos.size,
      last_updated: @last_updated,
      next_collection: @next_collection
    }
  end
  
  # 임시 사용자 인증 헬퍼 (나중에 실제 인증 시스템으로 대체)
  def user_signed_in?
    false # TODO: 실제 인증 구현 후 수정
  end
  
  def current_user
    nil # TODO: 실제 인증 구현 후 수정
  end
end
