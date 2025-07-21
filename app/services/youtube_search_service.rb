class YoutubeSearchService
  include HTTParty
  base_uri 'https://www.googleapis.com/youtube/v3'

  def initialize
    @api_key = ENV['YOUTUBE_API_KEY']
    raise "YouTube API key가 설정되지 않았습니다. Railway 환경변수에서 YOUTUBE_API_KEY를 확인하세요." unless @api_key
  end

  def search_videos(query:, region_code: 'KR', duration: nil, order: 'relevance', 
                   published_after: nil, published_before: nil, page_token: nil, max_results: 25, include_stats: true)
    
    options = {
      query: build_search_query(
        q: query,
        region_code: region_code,
        duration: duration,
        order: order,
        published_after: published_after,
        published_before: published_before,
        page_token: page_token,
        max_results: max_results
      ),
      timeout: 30
    }

    Rails.logger.info "YouTube Search API 요청: #{options[:query]}"

    response = self.class.get('/search', options)
    
    if response.success?
      search_result = parse_search_response(response.parsed_response)
      
      # 비디오 상세 정보 가져오기 (조회수, 좋아요 수 등)
      if include_stats && search_result[:items].any?
        video_ids = search_result[:items].map { |item| item[:video_id] }.compact
        video_stats = get_video_statistics(video_ids)
        
        # 검색 결과에 상세 정보 병합
        search_result[:items] = merge_video_statistics(search_result[:items], video_stats)
      end
      
      search_result
    else
      handle_api_error(response)
    end
  end

  # 비디오 상세 정보 (조회수, 좋아요 수, 댓글 수, 지속시간) 가져오기
  def get_video_statistics(video_ids)
    return {} if video_ids.empty?
    
    # 최대 50개씩 처리 (YouTube API 제한)
    video_ids_chunks = video_ids.each_slice(50).to_a
    all_video_stats = {}
    
    video_ids_chunks.each do |chunk|
      options = {
        query: {
          'key' => @api_key,
          'part' => 'statistics,contentDetails',
          'id' => chunk.join(','),
          'fields' => 'items(id,statistics,contentDetails)'
        },
        timeout: 30
      }
      
      Rails.logger.info "YouTube Videos API 요청: 비디오 #{chunk.length}개"
      
      response = self.class.get('/videos', options)
      
      if response.success?
        response.parsed_response['items']&.each do |item|
          all_video_stats[item['id']] = {
            view_count: item.dig('statistics', 'viewCount')&.to_i || 0,
            like_count: item.dig('statistics', 'likeCount')&.to_i || 0,
            comment_count: item.dig('statistics', 'commentCount')&.to_i || 0,
            duration: item.dig('contentDetails', 'duration'),
            duration_seconds: parse_duration_to_seconds(item.dig('contentDetails', 'duration'))
          }
        end
      else
        Rails.logger.error "YouTube Videos API Error: #{response.code} - #{response.body}"
      end
    end
    
    all_video_stats
  end

  private

  def build_search_query(q:, region_code:, duration:, order:, published_after:, 
                        published_before:, page_token:, max_results:)
    query_params = {
      'key' => @api_key,
      'part' => 'snippet',
      'type' => 'video',
      'q' => q,
      'regionCode' => region_code,
      'order' => order,
      'maxResults' => max_results,
      'fields' => 'nextPageToken,prevPageToken,pageInfo,items(id,snippet)'
    }

    # 비디오 길이 필터
    query_params['videoDuration'] = duration if duration.present?

    # 발행 날짜 필터
    query_params['publishedAfter'] = published_after if published_after.present?
    query_params['publishedBefore'] = published_before if published_before.present?

    # 페이지네이션
    query_params['pageToken'] = page_token if page_token.present?

    query_params
  end

  def parse_search_response(response)
    {
      items: response['items']&.map { |item| parse_video_item(item) } || [],
      next_page_token: response['nextPageToken'],
      prev_page_token: response['prevPageToken'],
      total_results: response.dig('pageInfo', 'totalResults'),
      results_per_page: response.dig('pageInfo', 'resultsPerPage')
    }
  end

  def parse_video_item(item)
    snippet = item['snippet']
    
    {
      video_id: item.dig('id', 'videoId'),
      title: snippet['title'],
      description: snippet['description'],
      channel_title: snippet['channelTitle'],
      channel_id: snippet['channelId'],
      published_at: DateTime.parse(snippet['publishedAt']),
      thumbnail_url: snippet.dig('thumbnails', 'medium', 'url') || 
                     snippet.dig('thumbnails', 'default', 'url'),
      thumbnail_high_url: snippet.dig('thumbnails', 'high', 'url'),
      watch_url: "https://www.youtube.com/watch?v=#{item.dig('id', 'videoId')}",
      # 초기값 (나중에 merge_video_statistics에서 업데이트)
      view_count: 0,
      like_count: 0,
      comment_count: 0,
      duration: nil,
      duration_seconds: 0
    }
  end

  # 검색 결과와 비디오 상세 정보 병합
  def merge_video_statistics(items, video_stats)
    items.map do |item|
      video_id = item[:video_id]
      if video_stats[video_id]
        item.merge(video_stats[video_id])
      else
        item
      end
    end
  end

  # YouTube duration 형식을 초로 변환 (PT1H2M3S -> 3723초)
  def parse_duration_to_seconds(duration_string)
    return 0 unless duration_string
    
    match = duration_string.match(/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/)
    return 0 unless match
    
    hours = match[1]&.to_i || 0
    minutes = match[2]&.to_i || 0
    seconds = match[3]&.to_i || 0
    
    hours * 3600 + minutes * 60 + seconds
  end

  # 조회수 포맷팅 (1000 -> 1K, 1000000 -> 1M)
  def self.format_view_count(count)
    return '0' unless count && count > 0
    
    case count
    when 0...1_000
      count.to_s
    when 1_000...1_000_000
      "#{(count / 1_000.0).round(1)}K"
    when 1_000_000...1_000_000_000
      "#{(count / 1_000_000.0).round(1)}M"
    else
      "#{(count / 1_000_000_000.0).round(1)}B"
    end
  end

  # 지속시간 포맷팅 (3661초 -> 1:01:01)
  def self.format_duration(seconds)
    return '0:00' unless seconds && seconds > 0
    
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    secs = seconds % 60
    
    if hours > 0
      "%d:%02d:%02d" % [hours, minutes, secs]
    else
      "%d:%02d" % [minutes, secs]
    end
  end

  def handle_api_error(response)
    error_message = case response.code
    when 400
      "잘못된 검색 요청입니다"
    when 403
      "API 할당량을 초과했거나 API 키가 유효하지 않습니다"
    when 404
      "요청한 리소스를 찾을 수 없습니다"
    when 500..599
      "YouTube 서버에 일시적인 문제가 발생했습니다"
    else
      "알 수 없는 오류가 발생했습니다"
    end

    Rails.logger.error "YouTube API Error #{response.code}: #{response.body}"
    
    raise StandardError, "#{error_message} (HTTP #{response.code})"
  end

  # 검색 필터 옵션들을 반환하는 유틸리티 메서드들
  def self.duration_options
    [
      ['모든 길이', ''],
      ['4분 미만 (짧은 영상)', 'short'],    # 4분 미만
      ['4분~20분 (중간 영상)', 'medium'],   # 4분~20분 (포함)
      ['20분 초과 (긴 영상)', 'long']       # 20분 초과
    ]
  end

  def self.order_options
    [
      ['관련성', 'relevance'],
      ['최신순', 'date'],
      ['조회수', 'viewCount'],
      ['평점', 'rating'],
      ['제목', 'title']
    ]
  end

  # 정렬 옵션 (클라이언트 사이드 정렬용)
  def self.sort_options
    [
      ['관련성 (기본)', 'relevance'],
      ['조회수 높은순', 'view_count_desc'],
      ['조회수 낮은순', 'view_count_asc'],
      ['좋아요 많은순', 'like_count_desc'],
      ['댓글 많은순', 'comment_count_desc'],
      ['최신순', 'published_desc'],
      ['오래된순', 'published_asc'],
      ['짧은 영상순', 'duration_asc'],
      ['긴 영상순', 'duration_desc'],
      ['제목 가나다순', 'title_asc'],
      ['제목 역순', 'title_desc']
    ]
  end

  def self.region_options
    [
      ['🇰🇷 한국', 'KR'],
      ['🇺🇸 미국', 'US'],
      ['🇯🇵 일본', 'JP'],
      ['🇻🇳 베트남', 'VN'],
      ['🇮🇩 인도네시아', 'ID'],
      ['🇬🇧 영국', 'GB'],
      ['🇩🇪 독일', 'DE'],
      ['🇫🇷 프랑스', 'FR'],
      ['🇮🇳 인도', 'IN'],
      ['🇧🇷 브라질', 'BR'],
      ['🇲🇽 멕시코', 'MX'],
      ['🇨🇦 캐나다', 'CA'],
      ['🇦🇺 호주', 'AU']
    ]
  end
end