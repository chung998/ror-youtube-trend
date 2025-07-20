class YoutubeSearchService
  include HTTParty
  base_uri 'https://www.googleapis.com/youtube/v3'

  def initialize
    @api_key = ENV['YOUTUBE_API_KEY'] || Rails.application.credentials.youtube_api_key
    raise "YouTube API key가 설정되지 않았습니다" unless @api_key
  end

  def search_videos(query:, region_code: 'KR', duration: nil, order: 'relevance', 
                   published_after: nil, published_before: nil, page_token: nil, max_results: 25)
    
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
      parse_search_response(response.parsed_response)
    else
      handle_api_error(response)
    end
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
      watch_url: "https://www.youtube.com/watch?v=#{item.dig('id', 'videoId')}"
    }
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
      ['20초 이하 (Shorts)', 'short'],    # 4분 미만
      ['20초~60초', 'medium'],             # 4분~20분
      ['60초 이상', 'long']                # 20분 이상
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

  def self.region_options
    [
      ['🇰🇷 한국', 'KR'],
      ['🇺🇸 미국', 'US'],
      ['🇯🇵 일본', 'JP'],
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