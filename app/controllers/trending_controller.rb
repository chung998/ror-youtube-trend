class TrendingController < ApplicationController
  before_action :set_region_and_type, only: [:index, :collect_country]
  before_action :set_region, only: [:collect_country]
  
  def index
    @videos = TrendingVideo.cached_trending(@region, @type)
    @collection_status = TrendingCollectionService.new.collection_status
    
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
  
  # 특정 국가 수집 (일반 + 쇼츠 통합)
  def collect_country
    # 수동 수집은 관리자만 가능
    return head :forbidden unless user_signed_in? && current_user&.admin?
    
    service = TrendingCollectionService.new
    result = service.collect_country(@region)
    
    respond_to do |format|
      if result[:success]
        format.html { redirect_back(fallback_location: root_path, notice: result[:message]) }
        format.json { render json: result }
      else
        status_code = result[:already_collected] ? :unprocessable_entity : :internal_server_error
        format.html { redirect_back(fallback_location: root_path, alert: result[:error]) }
        format.json { render json: result, status: status_code }
      end
    end
  end
  
  # 전체 국가 수집
  def collect_all_countries
    # 수동 수집은 관리자만 가능
    return head :forbidden unless user_signed_in? && current_user&.admin?
    
    service = TrendingCollectionService.new
    result = service.collect_all_countries
    
    respond_to do |format|
      if result[:success]
        format.html { redirect_back(fallback_location: root_path, notice: result[:message]) }
        format.json { render json: result }
      else
        format.html { redirect_back(fallback_location: root_path, alert: "전체 수집 실패: #{result[:results].select { |r| !r[:success] }.map { |r| r[:error] }.join(', ')}") }
        format.json { render json: result, status: :internal_server_error }
      end
    end
  end
  
  private
  
  def set_region_and_type
    @region = params[:region]&.upcase || 'KR'
    @type = params[:type] || 'all'
    
    # 유효하지 않은 지역 코드 처리
    unless %w[KR US JP GB DE FR VN ID].include?(@region)
      @region = 'KR'
    end
    
    # 유효하지 않은 타입 처리
    unless %w[all videos shorts].include?(@type)
      @type = 'all'
    end
  end
  
  def set_region
    @region = params[:region]&.upcase || 'KR'
    
    # 유효하지 않은 지역 코드 처리
    unless %w[KR US JP GB DE FR VN ID].include?(@region)
      @region = 'KR'
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
  

end
