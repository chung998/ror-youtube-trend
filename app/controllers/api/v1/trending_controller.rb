class Api::V1::TrendingController < ApplicationController
  before_action :set_region_and_type, only: [:index, :collect]
  
  def index
    @videos = TrendingVideo.cached_trending(@region, @type)
    @last_updated = get_last_updated_time
    @next_collection = CollectionLog.next_scheduled_time
    
    render json: {
      videos: @videos.map(&:as_json),
      meta: {
        region: @region,
        type: @type,
        total_count: @videos.size,
        last_updated: @last_updated,
        next_collection: @next_collection
      }
    }
  end
  
  def search
    @query = params[:q]
    @videos = []
    
    if @query.present?
      @videos = TrendingVideo.where(
        "title LIKE ? OR channel_title LIKE ?", 
        "%#{@query}%", "%#{@query}%"
      ).recent.popular.limit(50)
    end
    
    render json: {
      videos: @videos.map(&:as_json),
      meta: {
        query: @query,
        total_count: @videos.size
      }
    }
  end
  
  def collect
    # 수동 수집 트리거 (관리자 전용)
    return render json: { error: 'Forbidden' }, status: :forbidden unless user_signed_in? && current_user.admin?
    
    # TODO: CollectTrendingDataJob이 구현되면 활성화
    # CollectTrendingDataJob.perform_later(@region, @type)
    
    render json: { 
      status: 'started', 
      region: @region, 
      type: @type,
      message: '데이터 수집이 시작되었습니다.'
    }
  end
  
  private
  
  def set_region_and_type
    @region = params[:region]&.upcase || 'KR'
    @type = params[:type] || 'all'
    
    # 유효하지 않은 지역 코드 처리 (베트남, 인도네시아 추가)
    unless %w[KR US JP GB DE FR VN ID].include?(@region)
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
  
  # 임시 사용자 인증 헬퍼 (나중에 실제 인증 시스템으로 대체)
  def user_signed_in?
    false # TODO: 실제 인증 구현 후 수정
  end
  
  def current_user
    nil # TODO: 실제 인증 구현 후 수정
  end
end
