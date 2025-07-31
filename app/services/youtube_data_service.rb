require 'google/apis/youtube_v3'
require 'googleauth'

class YoutubeDataService
  include YoutubeRegions
  
  YOUTUBE_API_KEY = ENV['YOUTUBE_API_KEY']
  
  def initialize
    @service = Google::Apis::YoutubeV3::YouTubeService.new
    @service.key = YOUTUBE_API_KEY
  end
  
  # 메인 데이터 수집 메서드 (trending API만 사용)
  def fetch_trending_videos(region_code, type = 'all', max_results = 50)
    # trending API만 사용 (복잡한 search API 쇼츠 수집 로직 제거)
    videos = fetch_regular_videos(region_code, max_results)
    
    # 타입별 필터링
    case type
    when 'shorts'
      videos.select { |video| video[:is_shorts] }
    when 'videos'
      videos.reject { |video| video[:is_shorts] }
    else
      videos # 'all'인 경우 쇼츠와 일반 영상 모두 포함
    end
  end
  
  private
  
  # trending API로 인기 비디오 수집 (쇼츠+일반 영상 모두 포함)
  def fetch_regular_videos(region_code, max_results = 50)
    begin
      response = @service.list_videos(
        'snippet,statistics,contentDetails',
        chart: 'mostPopular',
        region_code: region_code,
        max_results: max_results,
        video_category_id: nil # 모든 카테고리
      )
      
      videos = response.items.map { |item| parse_video_data(item) }
      
      Rails.logger.info "#{region_code} 지역: 총 #{videos.length}개 수집 (쇼츠 #{videos.count { |v| v[:is_shorts] }}개 포함)"
      videos
      
    rescue Google::Apis::Error => e
      Rails.logger.error "YouTube trending API 에러: #{e.message}"
      raise "YouTube trending API 에러: #{e.message}"
    end
  end
  
  # 쇼츠 수집 기능 제거 (일반 인기 영상만 수집)
  # def fetch_popular_shorts(region_code, max_results = 25)
  #   # 쇼츠 수집 로직 제거됨 - 일반 인기 영상만 수집하도록 변경
  # end
  
  # API 응답 데이터를 모델 형식으로 변환
  def parse_video_data(item)
    duration_seconds = parse_duration(item.content_details.duration)
    
    {
      video_id: item.id,
      title: item.snippet.title,
      description: item.snippet.description,
      channel_title: item.snippet.channel_title,
      channel_id: item.snippet.channel_id,
      view_count: item.statistics.view_count&.to_i || 0,
      like_count: item.statistics.like_count&.to_i || 0,
      comment_count: item.statistics.comment_count&.to_i || 0,
      published_at: item.snippet.published_at,
      duration: item.content_details.duration,
      thumbnail_url: item.snippet.thumbnails&.high&.url,
      is_shorts: duration_seconds <= 60 && duration_seconds > 0,
      collected_at: Time.current
    }
  end
  
  # YouTube 기간 형식을 초로 변환 (PT1M30S -> 90초)
  def parse_duration(duration_string)
    return 0 unless duration_string
    
    match = duration_string.match(/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/)
    return 0 unless match
    
    hours = match[1]&.to_i || 0
    minutes = match[2]&.to_i || 0
    seconds = match[3]&.to_i || 0
    
    hours * 3600 + minutes * 60 + seconds
  end
  
  # 지역 코드에 따른 언어 설정
  def get_language_for_region(region_code)
    YoutubeRegions.language(region_code)
  end
  
  # 쇼츠 관련 메서드 제거 (더 이상 사용하지 않음)
  # def get_shorts_keywords_for_region(region_code)
  #   # 쇼츠 수집 기능 제거로 인해 더 이상 사용하지 않음
  # end
end