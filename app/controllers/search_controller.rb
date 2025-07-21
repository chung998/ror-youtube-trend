class SearchController < ApplicationController
  before_action :require_authentication  # 로그인 필요

  def index
    # 검색 페이지 기본 화면 (필터 없이)
  end

  def results
    @query = search_params[:q]
    @region = search_params[:region] || 'KR'
    @duration = search_params[:duration]
    @order = search_params[:order] || 'relevance'
    @sort = search_params[:sort] || 'relevance'
    @max_results = [search_params[:max_results].to_i, 50].min # 최대 50개 제한
    @max_results = 25 if @max_results <= 0 # 기본값 25개
    @published_after = parse_date_start(search_params[:published_after])
    @published_before = parse_date_end(search_params[:published_before])
    @page_token = search_params[:page_token]

    if @query.present?
      begin
        # YouTube Search API 호출
        @search_results = youtube_search_service.search_videos(
          query: @query,
          region_code: @region,
          duration: @duration,
          order: @order,
          published_after: @published_after,
          published_before: @published_before,
          page_token: @page_token,
          max_results: @max_results,
          include_stats: true  # 상세 정보 포함
        )
        
        # 클라이언트 사이드 정렬 적용
        if @search_results && @search_results[:items].any?
          @search_results[:items] = apply_custom_sorting(@search_results[:items], @sort)
        end
        
      rescue => e
        Rails.logger.error "YouTube Search API Error: #{e.message}"
        @error = "검색 중 오류가 발생했습니다: #{e.message}"
        @search_results = nil
      end
    end

    render :index
  end

  private

  def search_params
    params.permit(:q, :region, :duration, :order, :sort, :max_results, :published_after, :published_before, :page_token, :commit)
  end

  def parse_date_start(date_string)
    return nil if date_string.blank?
    # YouTube API는 RFC 3339 형식을 요구 (타임존 포함)
    Date.parse(date_string).beginning_of_day.utc.iso8601
  rescue ArgumentError
    nil
  end

  def parse_date_end(date_string)
    return nil if date_string.blank?
    # YouTube API는 RFC 3339 형식을 요구 (타임존 포함)
    Date.parse(date_string).end_of_day.utc.iso8601
  rescue ArgumentError
    nil
  end

  def youtube_search_service
    @youtube_search_service ||= YoutubeSearchService.new
  end

  # 검색 결과에 커스텀 정렬 적용
  def apply_custom_sorting(items, sort_type)
    case sort_type
    when 'view_count_desc'
      items.sort_by { |item| -item[:view_count].to_i }
    when 'view_count_asc'
      items.sort_by { |item| item[:view_count].to_i }
    when 'like_count_desc'
      items.sort_by { |item| -item[:like_count].to_i }
    when 'comment_count_desc'
      items.sort_by { |item| -item[:comment_count].to_i }
    when 'published_desc'
      items.sort_by { |item| -item[:published_at].to_i }
    when 'published_asc'
      items.sort_by { |item| item[:published_at].to_i }
    when 'duration_desc'
      items.sort_by { |item| -item[:duration_seconds].to_i }
    when 'duration_asc'
      items.sort_by { |item| item[:duration_seconds].to_i }
    when 'title_asc'
      items.sort_by { |item| item[:title].downcase }
    when 'title_desc'
      items.sort_by { |item| item[:title].downcase }.reverse
    else
      # 'relevance' 또는 기본값: 원래 순서 유지
      items
    end
  end
end