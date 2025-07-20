class HealthController < ApplicationController
  def show
    render json: {
      status: 'ok',
      timestamp: Time.current.iso8601,
      version: '1.0.0',
      database: database_status,
      queue: queue_status,
      cache: cache_status,
      last_collection: last_collection_status
    }
  end

  private

  def database_status
    TrendingVideo.count
    'connected'
  rescue
    'error'
  end

  def queue_status
    ActiveJob::Base.queue_adapter.class.name
  rescue
    'error'  
  end

  def cache_status
    Rails.cache.write('health_check', 'ok')
    Rails.cache.read('health_check') == 'ok' ? 'connected' : 'error'
  rescue
    'error'
  end

  def last_collection_status
    last_log = CollectionLog.successful.last
    {
      last_successful: last_log&.completed_at&.iso8601,
      next_scheduled: CollectionLog.next_scheduled_time.iso8601
    }
  end
end
