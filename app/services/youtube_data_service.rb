require 'net/http'
require 'json'
require 'uri'

class YoutubeDataService
  YOUTUBE_API_KEY = ENV['YOUTUBE_API_KEY']
  BASE_URL = 'https://www.googleapis.com/youtube/v3'
  
  def initialize
    @http = Net::HTTP
  end
  
  # 메인 데이터 수집 메서드
  def fetch_trending_videos(region_code, type = 'all', max_results = 50)
    url = build_url(region_code, max_results)
    response = make_api_request(url)
    
    return [] unless response['items']
    
    videos = response['items'].map { |item| parse_video_data(item) }
    
    # 타입별 필터링
    filter_videos_by_type(videos, type)
  end
  
  private
  
  # YouTube API URL 생성
  def build_url(region_code, max_results)
    params = {
      part: 'snippet,statistics,contentDetails',
      chart: 'mostPopular',
      regionCode: region_code,
      maxResults: max_results,
      key: YOUTUBE_API_KEY
    }
    
    "#{BASE_URL}/videos?#{params.to_query}"
  end
  
  # API 요청 실행
  def make_api_request(url)
    uri = URI(url)
    response = Net::HTTP.get_response(uri)
    
    unless response.code == '200'
      Rails.logger.error "YouTube API 에러: #{response.code} - #{response.body}"
      raise "YouTube API 에러: #{response.code}"
    end
    
    JSON.parse(response.body)
  rescue JSON::ParserError => e
    Rails.logger.error "YouTube API 응답 파싱 실패: #{e.message}"
    raise "YouTube API 응답 파싱 실패: #{e.message}"
  rescue => e
    Rails.logger.error "YouTube API 요청 실패: #{e.message}"
    raise "YouTube API 요청 실패: #{e.message}"
  end
  
  # API 응답 데이터를 모델 형식으로 변환
  def parse_video_data(item)
    duration_seconds = parse_duration(item.dig('contentDetails', 'duration'))
    
    {
      video_id: item['id'],
      title: item.dig('snippet', 'title'),
      description: item.dig('snippet', 'description'),
      channel_title: item.dig('snippet', 'channelTitle'),
      channel_id: item.dig('snippet', 'channelId'),
      view_count: item.dig('statistics', 'viewCount')&.to_i || 0,
      like_count: item.dig('statistics', 'likeCount')&.to_i || 0,
      comment_count: item.dig('statistics', 'commentCount')&.to_i || 0,
      published_at: item.dig('snippet', 'publishedAt'),
      duration: item.dig('contentDetails', 'duration'),
      thumbnail_url: item.dig('snippet', 'thumbnails', 'high', 'url'),
      is_shorts: duration_seconds <= 60,
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
  
  # 타입별 비디오 필터링
  def filter_videos_by_type(videos, type)
    case type
    when 'shorts'
      videos.select { |v| v[:is_shorts] }
    when 'videos'
      videos.reject { |v| v[:is_shorts] }
    else
      videos
    end
  end
end