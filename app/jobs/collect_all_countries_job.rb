class CollectAllCountriesJob < ApplicationJob
  include YoutubeRegions
  queue_as :default
  
  def perform(date = Date.current)
    Rails.logger.info "🚀 전체 국가 데이터 수집 시작 (서울 시간: #{Time.current.in_time_zone('Asia/Seoul')})"
    
    begin
      # TrendingCollectionService를 사용하여 전체 국가 데이터 수집
      service = TrendingCollectionService.new
      result = service.collect_all_countries(date)
      
      if result[:success]
        Rails.logger.info "✅ 전체 국가 수집 완료: #{result[:successful_countries]}/#{result[:total_countries]}개 국가, 총 #{result[:total_videos_collected]}개 비디오"
        
        # 전체 캐시 무효화
        invalidate_all_cache(date)
        
        # 실시간 알림 (향후 ActionCable 구현 시)
        broadcast_complete_update(result)
        
        result[:total_videos_collected]
      else
        raise StandardError, "전체 수집 실패: #{result[:message]}"
      end
      
    rescue => e
      Rails.logger.error "❌ 전체 국가 데이터 수집 실패: #{e.message}"
      
      # 에러 알림 (향후 ActionCable 구현 시)  
      broadcast_complete_error(e.message)
      
      raise e
    end
  end
  
  private
  
  def invalidate_all_cache(date)
    # 모든 지역 및 타입의 캐시 무효화
    regions = YoutubeRegions.primary_codes
    types = %w[all videos shorts]
    
    regions.each do |region|
      types.each do |type|
        Rails.cache.delete("trending_#{region}_#{type}_#{date}")
      end
    end
    
    Rails.logger.info "🗑️ 전체 캐시 무효화 완료"
  end
  
  def broadcast_complete_update(result)
    # 향후 ActionCable 구현 시 실시간 알림
    # ActionCable.server.broadcast('trending_updates', {
    #   type: 'all_countries_completed',
    #   successful_countries: result[:successful_countries],
    #   total_countries: result[:total_countries],
    #   total_videos: result[:total_videos_collected],
    #   timestamp: Time.current.iso8601
    # })
  end
  
  def broadcast_complete_error(error_message)
    # 향후 ActionCable 구현 시 에러 알림
    # ActionCable.server.broadcast('admin_channel', {
    #   type: 'all_countries_error',
    #   message: "전체 국가 수집 실패: #{error_message}",
    #   timestamp: Time.current.iso8601
    # })
  end
end