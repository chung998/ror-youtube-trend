class SearchController < ApplicationController
  def index
    # 검색 페이지 기본 화면 (필터 없이)
  end

  def results
    @query = search_params[:q]
    @region = search_params[:region] || 'KR'
    @duration = search_params[:duration]
    @order = search_params[:order] || 'relevance'
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
          page_token: @page_token
        )
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
    params.permit(:q, :region, :duration, :order, :published_after, :published_before, :page_token, :commit)
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
end