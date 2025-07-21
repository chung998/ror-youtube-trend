class CollectTrendingDataJob < ApplicationJob
  queue_as :default
  
  def perform(region_code = 'KR', collection_type = 'all')
    Rails.logger.info "🚀 #{region_code} 지역 #{collection_type} 데이터 수집 시작"
    
    # 수집 로그 시작
    collection_log = CollectionLog.create!(
      region_code: region_code,
      collection_type: collection_type,
      status: :running,
      started_at: Time.current
    )
    
    begin
      # TrendingCollectionService를 사용하여 데이터 수집
      service = TrendingCollectionService.new
      result = service.collect_country(region_code, Date.current)
      
      if result[:success]
        # 수집 성공
        collection_log.update!(
          status: :completed,
          videos_collected: result[:videos_collected],
          completed_at: Time.current
        )
        
        Rails.logger.info "✅ #{region_code} 수집 완료: #{result[:videos_collected]}개 저장"
        
        # 캐시 무효화
        invalidate_cache(region_code)
        
        # 실시간 알림 (향후 ActionCable 구현 시)
        broadcast_update(region_code, result[:videos_collected])
        
        result[:videos_collected]
      else
        # 수집 실패 (이미 수집된 경우 등)
        if result[:already_collected]
          collection_log.update!(
            status: :completed,
            videos_collected: 0,
            completed_at: Time.current,
            error_message: result[:error]
          )
          Rails.logger.info "ℹ️ #{region_code} 오늘 이미 수집됨"
        else
          raise StandardError, result[:error]
        end
        0
      end
      
    rescue => e
      # 수집 실패
      collection_log.update!(
        status: :failed,
        error_message: e.message,
        completed_at: Time.current
      )
      
      Rails.logger.error "❌ #{region_code} 데이터 수집 실패: #{e.message}"
      
      # 에러 알림 (향후 ActionCable 구현 시)
      broadcast_error(region_code, e.message)
      
      raise e
    end
  end
  
  private
  
  def invalidate_cache(region_code)
    # 지역별 캐시 무효화
    ['all', 'videos', 'shorts'].each do |type|
      Rails.cache.delete("trending_#{region_code}_#{type}_#{Date.current}")
    end
    Rails.logger.info "🗑️ #{region_code} 캐시 무효화 완료"
  end
  
  def broadcast_update(region_code, count)
    # 향후 ActionCable 구현 시 실시간 알림
    # ActionCable.server.broadcast('trending_updates', {
    #   type: 'collection_completed',
    #   region: region_code,
    #   count: count,
    #   timestamp: Time.current.iso8601
    # })
  end
  
  def broadcast_error(region_code, error_message)
    # 향후 ActionCable 구현 시 에러 알림
    # ActionCable.server.broadcast('admin_channel', {
    #   type: 'error',
    #   message: "#{region_code} 지역 수집 실패: #{error_message}"
    # })
  end
end 