class TrendingCollectionService
  SUPPORTED_REGIONS = %w[KR US JP GB DE FR VN ID].freeze
  
  def initialize
    @youtube_service = YoutubeDataService.new
  end
  
  # 특정 국가의 인기 영상 수집 (trending API만 사용)
  def collect_country(region_code, date = Date.current)
    region_code = region_code.upcase
    return { success: false, error: "지원하지 않는 국가입니다" } unless SUPPORTED_REGIONS.include?(region_code)
    
    # 이미 오늘 수집했는지 확인
    if TrendingVideo.by_region(region_code).by_date(date).exists?
      return { 
        success: false, 
        error: "#{region_code} 지역은 #{date} 날짜에 이미 수집되었습니다",
        already_collected: true
      }
    end
    
    begin
      collection_log = create_collection_log(region_code, date)
      
      # trending API만 사용 (복잡한 search API 쇼츠 수집 로직 제거)
      all_videos = @youtube_service.fetch_trending_videos(region_code, 'all', 50)
      saved_count = 0
      
      all_videos.each do |video_data|
        begin
          # 먼저 기존 비디오가 있는지 확인
          existing_video = TrendingVideo.find_by(
            video_id: video_data[:video_id],
            region_code: region_code,
            collection_date: date
          )
          
          unless existing_video
            # 새 비디오 생성
            TrendingVideo.create!(
              video_id: video_data[:video_id],
              title: video_data[:title],
              description: video_data[:description],
              channel_title: video_data[:channel_title],
              channel_id: video_data[:channel_id],
              view_count: video_data[:view_count],
              like_count: video_data[:like_count],
              comment_count: video_data[:comment_count],
              published_at: video_data[:published_at],
              duration: video_data[:duration],
              thumbnail_url: video_data[:thumbnail_url],
              is_shorts: video_data[:is_shorts],
              region_code: region_code,
              collection_date: date
            )
            saved_count += 1
          else
            Rails.logger.debug "중복 비디오 무시: #{video_data[:video_id]} (#{region_code}, #{date})"
          end
          
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
          Rails.logger.warn "비디오 저장 실패/중복 (#{video_data[:video_id]}): #{e.message}"
          # 에러가 발생해도 계속 진행
        end
      end
      
      # 수집 로그 업데이트
      collection_log.update!(
        status: 'completed',
        completed_at: Time.current,
        videos_collected: saved_count
      )
      
      # 캐시 무효화
      invalidate_cache(region_code, date)
      
      {
        success: true,
        region: region_code,
        date: date,
        videos_collected: saved_count,
        message: "#{region_code} 지역 데이터 수집 완료 (#{saved_count}개 비디오)"
      }
      
    rescue => e
      collection_log&.update!(
        status: 'failed',
        completed_at: Time.current,
        error_message: e.message
      )
      
      Rails.logger.error "#{region_code} 데이터 수집 실패: #{e.message}"
      
      {
        success: false,
        region: region_code,
        error: e.message
      }
    end
  end
  
  # 모든 국가 데이터 수집
  def collect_all_countries(date = Date.current)
    results = []
    total_success = 0
    total_videos = 0
    
    SUPPORTED_REGIONS.each do |region|
      result = collect_country(region, date)
      results << result
      
      if result[:success]
        total_success += 1
        total_videos += result[:videos_collected] || 0
      end
    end
    
    {
      success: total_success > 0,
      total_countries: SUPPORTED_REGIONS.length,
      successful_countries: total_success,
      total_videos_collected: total_videos,
      results: results,
      message: "전체 수집 완료: #{total_success}/#{SUPPORTED_REGIONS.length} 국가 성공"
    }
  end
  
  # 오늘의 수집 상태 확인
  def collection_status(date = Date.current)
    TrendingVideo.collection_status_today
  end
  
  private
  
  def create_collection_log(region_code, date)
    CollectionLog.create!(
      region_code: region_code,
      collection_type: 'all',
      status: 'running',
      started_at: Time.current,
      api_calls_used: 1
    )
  end
  
  def invalidate_cache(region_code, date)
    %w[all videos shorts].each do |type|
      Rails.cache.delete("trending_#{region_code}_#{type}_#{date}")
    end
  end
end