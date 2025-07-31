class TrendingVideo < ApplicationRecord
  include YoutubeRegions
  
  validates :video_id, presence: true, uniqueness: { scope: [:region_code, :collection_date] }
  validates :region_code, inclusion: { in: YoutubeRegions.primary_codes }
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
  scope :mega_hits, -> { where('view_count >= ?', 10_000_000) }
  
  # YouTube URL 생성
  def youtube_url
    "https://www.youtube.com/watch?v=#{video_id}"
  end
  
  # 조회수 포맷팅 (한글 단위: 억, 만, 천)
  def formatted_view_count
    case view_count
    when 0...1_000
      view_count.to_s
    when 1_000...10_000
      "#{(view_count / 1_000.0).round}천"
    when 10_000...100_000_000
      "#{(view_count / 10_000.0).round}만"
    else
      "#{(view_count / 100_000_000.0).round}억"
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
    YoutubeRegions.stats_regions.map do |region_code, region_name|
      {
        region: region_code,
        collected: collected_today?(region_code),
        count: by_region(region_code).today.count
      }
    end
  end

  # 메가히트 영상 조회 (조회수 1천만 이상, 지역 무관, video_id 기준 중복 제거)
  def self.get_mega_hits(limit = 12)
    # video_id별로 region_code 순서상 첫 번째 레코드만 선택하여 중복 제거
    # SQLite와 PostgreSQL 모두 호환되는 방식 사용
    subquery = mega_hits
      .select('video_id, MIN(region_code) as first_region')
      .group(:video_id)
    
    videos = mega_hits
      .joins("INNER JOIN (#{subquery.to_sql}) AS unique_videos ON trending_videos.video_id = unique_videos.video_id AND trending_videos.region_code = unique_videos.first_region")
      .order(view_count: :desc)
      .limit(limit)
    
    # 각 비디오에 대해 모든 region_code들을 추가로 수집
    videos.map do |video|
      region_codes = mega_hits
        .where(video_id: video.video_id)
        .distinct
        .pluck(:region_code)
        .sort
      
      # region_codes 속성을 동적으로 추가
      video.define_singleton_method(:region_codes) { region_codes }
      video
    end
  end
end
