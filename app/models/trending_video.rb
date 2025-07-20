class TrendingVideo < ApplicationRecord
  # 사용자별 분리 제거 - 단일 테이블로 관리
  
  validates :video_id, presence: true, uniqueness: { scope: [:region_code, :collection_date] }
  validates :region_code, inclusion: { in: %w[KR US JP GB DE FR VN ID] }
  validates :title, presence: true
  validates :channel_title, presence: true
  validates :channel_id, presence: true
  validates :published_at, presence: true
  validates :collection_date, presence: true
  
  # 일일 단위 수집을 위한 스코프
  scope :today, -> { where(collection_date: Date.current) }
  scope :by_date, ->(date) { where(collection_date: date) }
  scope :by_region, ->(region) { where(region_code: region) }
  scope :shorts, -> { where(is_shorts: true) }
  scope :videos, -> { where(is_shorts: false) }
  scope :popular, -> { order(view_count: :desc) }
  scope :recent_days, ->(days = 7) { where('collection_date >= ?', days.days.ago) }
  
  # YouTube URL 생성
  def youtube_url
    "https://www.youtube.com/watch?v=#{video_id}"
  end
  
  # 조회수 포맷팅
  def formatted_view_count
    case view_count
    when 0...1_000
      view_count.to_s
    when 1_000...1_000_000
      "#{(view_count / 1_000.0).round(1)}K"
    when 1_000_000...1_000_000_000
      "#{(view_count / 1_000_000.0).round(1)}M"
    else
      "#{(view_count / 1_000_000_000.0).round(1)}B"
    end
  end
  
  # 일일 단위 캐시된 트렌딩 데이터
  def self.cached_trending(region, type = 'all', date = Date.current)
    cache_key = "trending_#{region}_#{type}_#{date}"
    
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      videos = by_region(region).by_date(date).popular.limit(50)
      videos = videos.shorts if type == 'shorts'
      videos = videos.videos if type == 'videos'
      videos.to_a
    end
  end
  
  # 국가별 오늘 수집 여부 확인
  def self.collected_today?(region)
    by_region(region).today.exists?
  end
  
  # 모든 국가의 오늘 수집 상태
  def self.collection_status_today
    %w[KR US JP GB DE FR].map do |region|
      {
        region: region,
        collected: collected_today?(region),
        count: by_region(region).today.count
      }
    end
  end
end
