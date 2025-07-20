class TrendingVideo < ApplicationRecord
  belongs_to :user, optional: true
  
  validates :video_id, presence: true, uniqueness: { scope: [:region_code, :collected_at] }
  validates :region_code, inclusion: { in: %w[KR US JP GB DE FR] }
  validates :title, presence: true
  validates :channel_title, presence: true
  validates :channel_id, presence: true
  validates :published_at, presence: true
  validates :collected_at, presence: true
  
  scope :recent, -> { where('collected_at > ?', 24.hours.ago) }
  scope :by_region, ->(region) { where(region_code: region) }
  scope :shorts, -> { where(is_shorts: true) }
  scope :videos, -> { where(is_shorts: false) }
  scope :popular, -> { order(view_count: :desc) }
  
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
  
  # Solid Cache 활용한 캐시된 트렌딩 데이터
  def self.cached_trending(region, type = 'all')
    cache_key = "trending_#{region}_#{type}_#{Date.current}"
    
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      videos = by_region(region).recent.popular.limit(50)
      videos = videos.shorts if type == 'shorts'
      videos = videos.videos if type == 'videos'
      videos.to_a
    end
  end
end
