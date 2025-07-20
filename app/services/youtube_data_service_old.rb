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
    if type == 'shorts'
      # 쇼츠의 경우 Search API 사용
      fetch_popular_shorts(region_code, max_results)
    else
      # 일반 비디오는 기존 trending API 사용
      url = build_url(region_code, max_results)
      response = make_api_request(url)
      
      return [] unless response['items']
      
      videos = response['items'].map { |item| parse_video_data(item) }
      
      # 타입별 필터링
      filter_videos_by_type(videos, type)
    end
  end
  
  # Search API를 이용한 지역별 인기 쇼츠 수집 (하이브리드 방식)
  def fetch_popular_shorts(region_code, max_results = 50)
    shorts_results = []
    
    # 1. 먼저 trending API에서 모든 비디오를 가져와서 쇼츠 찾기
    trending_url = build_url(region_code, 50)
    trending_response = make_api_request(trending_url)
    
    if trending_response['items']
      trending_videos = trending_response['items'].map { |item| parse_video_data(item) }
      trending_shorts = trending_videos.select { |video| video[:is_shorts] }
      shorts_results.concat(trending_shorts)
    end
    
    # 2. Search API로 추가 쇼츠 검색 (지역 코드 없이, 최근 1주일)
    if shorts_results.length < max_results
      begin
        published_after = 1.week.ago.iso8601
        search_url = build_search_url_for_shorts(published_after, max_results - shorts_results.length)
        search_response = make_api_request(search_url)
        
        if search_response['items']
          video_ids = search_response['items'].map { |item| item.dig('id', 'videoId') }.compact
          
          if video_ids.any?
            search_videos = fetch_videos_details(video_ids)
            search_shorts = search_videos.select { |video| video[:is_shorts] }
            shorts_results.concat(search_shorts)
          end
        end
      rescue => e
        Rails.logger.warn "Search API에서 쇼츠 수집 실패: #{e.message}"
        # trending에서 찾은 쇼츠만 사용
      end
    end
    
    # 조회수순으로 정렬하고 중복 제거
    shorts_results.uniq { |video| video[:video_id] }
                  .sort_by { |video| -video[:view_count] }
                  .first(max_results)
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
  
  # Search API URL 생성 (쇼츠 검색용 - 지역 코드 포함)
  def build_search_url(region_code, published_after, max_results)
    params = {
      part: 'snippet',
      type: 'video',
      order: 'viewCount',
      publishedAfter: published_after,
      regionCode: region_code,
      videoDuration: 'short',  # 4분 이하 비디오
      maxResults: [max_results * 2, 50].min,  # 더 많이 가져와서 쇼츠만 필터링
      key: YOUTUBE_API_KEY
    }
    
    "#{BASE_URL}/search?#{params.to_query}"
  end
  
  # Search API URL 생성 (쇼츠 검색용 - 지역 코드 없음, 전세계)
  def build_search_url_for_shorts(published_after, max_results)
    params = {
      part: 'snippet',
      type: 'video',
      order: 'viewCount',
      publishedAfter: published_after,
      videoDuration: 'short',  # 4분 이하 비디오
      maxResults: [max_results * 3, 50].min,  # 더 많이 가져와서 쇼츠만 필터링
      relevanceLanguage: 'ja',  # 일본어 관련성 높이기
      key: YOUTUBE_API_KEY
    }
    
    "#{BASE_URL}/search?#{params.to_query}"
  end
  
  # 비디오 세부 정보 가져오기 (video IDs 기반)
  def fetch_videos_details(video_ids)
    return [] if video_ids.empty?
    
    # 한 번에 최대 50개까지만 요청 가능
    video_ids = video_ids.first(50)
    
    params = {
      part: 'snippet,statistics,contentDetails',
      id: video_ids.join(','),
      key: YOUTUBE_API_KEY
    }
    
    url = "#{BASE_URL}/videos?#{params.to_query}"
    response = make_api_request(url)
    
    return [] unless response['items']
    
    response['items'].map { |item| parse_video_data(item) }
  end
end