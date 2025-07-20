class CollectionLog < ApplicationRecord
  enum :status, { pending: 0, running: 1, completed: 2, failed: 3 }
  
  validates :region_code, presence: true
  validates :collection_type, inclusion: { in: %w[videos shorts all] }
  validates :started_at, presence: true
  
  scope :today, -> { where(created_at: Date.current.all_day) }
  scope :recent_failures, -> { failed.where('created_at > ?', 1.day.ago) }
  scope :successful, -> { completed.where('videos_collected > 0') }
  
  # 다음 예정된 수집 시간 계산
  def self.next_scheduled_time
    now = Time.current
    next_hours = [6, 12, 18].find { |h| h > now.hour }
    
    if next_hours
      now.change(hour: next_hours, min: 0, sec: 0)
    else
      now.tomorrow.change(hour: 6, min: 0, sec: 0)
    end
  end
  
  # 실행 시간 포맷팅
  def execution_time_formatted
    return '알 수 없음' unless started_at && completed_at
    
    duration = completed_at - started_at
    "#{duration.round(2)}초"
  end
end
