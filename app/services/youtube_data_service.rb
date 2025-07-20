require 'google/apis/youtube_v3'
require 'googleauth'

class YoutubeDataService
  YOUTUBE_API_KEY = ENV['YOUTUBE_API_KEY']
  
  def initialize
    @service = Google::Apis::YoutubeV3::YouTubeService.new
    @service.key = YOUTUBE_API_KEY
  end
  
  # 메인 데이터 수집 메서드
  def fetch_trending_videos(region_code, type = 'all', max_results = 50)
    case type
    when 'shorts'
      fetch_popular_shorts(region_code, max_results)
    when 'videos'
      fetch_regular_videos(region_code, max_results)
    else
      # 'all'인 경우 일반 비디오와 쇼츠를 따로 수집해서 합침
      regular_videos = fetch_regular_videos(region_code, max_results / 2)
      shorts_videos = fetch_popular_shorts(region_code, max_results / 2)
      regular_videos + shorts_videos
    end
  end
  
  private
  
  # 일반 비디오 수집 (trending API 사용)
  def fetch_regular_videos(region_code, max_results = 25)
    begin
      response = @service.list_videos(
        'snippet,statistics,contentDetails',
        chart: 'mostPopular',
        region_code: region_code,
        max_results: max_results,
        video_category_id: nil # 모든 카테고리
      )
      
      videos = response.items.map { |item| parse_video_data(item) }
      # 일반 비디오만 필터링 (60초 초과)
      videos.reject { |video| video[:is_shorts] }
      
    rescue Google::Apis::Error => e
      Rails.logger.error "YouTube trending API 에러: #{e.message}"
      raise "YouTube trending API 에러: #{e.message}"
    end
  end
  
  # 쇼츠 수집 (search API 사용)
  def fetch_popular_shorts(region_code, max_results = 25)
    shorts_results = []
    one_week_ago = 1.week.ago
    
    # 여러 키워드로 검색해서 다양한 쇼츠 수집
    search_keywords = get_shorts_keywords_for_region(region_code)
    
    # 단순 검색으로 조회수 순 10개만 가져오기
    begin
      search_response = @service.list_searches(
        'snippet',
        q: 'a', # 가장 일반적인 문자
        type: 'video',
        order: 'viewCount', # 조회수 순으로 정렬
        region_code: region_code,
        video_duration: 'short', # 4분 이하 (쇼츠)
        max_results: 10, # 10개만 가져오기
        relevance_language: get_language_for_region(region_code)
      )
        
        if search_response.items.any?
          video_ids = search_response.items.map(&:id).map(&:video_id)
          
          # 비디오 세부정보 가져오기
          details_response = @service.list_videos(
            'snippet,statistics,contentDetails',
            id: video_ids.join(',')
          )
          
          shorts_candidates = details_response.items.map { |item| parse_video_data(item) }
          
          # 1. 실제 쇼츠만 필터링 (60초 이하)
          # 2. 최근 1주일간 게시된 것만 필터링
          recent_shorts = shorts_candidates.select do |video| 
            video[:is_shorts] && 
            video[:published_at] && 
            Time.parse(video[:published_at].to_s) >= one_week_ago
          end
          
          shorts_results.concat(recent_shorts)
        end
        
      rescue Google::Apis::Error => e
        Rails.logger.warn "YouTube search API에서 쇼츠 수집 실패: #{e.message}"
      end
    
    # 조회수순으로 이미 정렬되어 있으므로 그대로 반환
    shorts_results.uniq { |video| video[:video_id] }
                  .first(max_results)
  end
  
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
    case region_code.upcase
    when 'KR' then 'ko'
    when 'JP' then 'ja'
    when 'US', 'GB' then 'en'
    when 'DE' then 'de'
    when 'FR' then 'fr'
    when 'VN' then 'vi'
    when 'ID' then 'id'
    else 'en'
    end
  end
  
  # 지역별 쇼츠 검색 키워드 설정 (매우 일반적인 키워드 사용)
  def get_shorts_keywords_for_region(region_code)
    # 모든 지역에서 공통으로 사용할 수 있는 매우 일반적인 키워드들
    # 띄어쓰기나 모든 제목에 들어갈 수 있는 단어들 사용
    [' ', 'a', 'the', 'and', 'in', 'to']
  end
end