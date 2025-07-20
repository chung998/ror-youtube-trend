class UpdateTrendingVideosSchema < ActiveRecord::Migration[8.0]
  def change
    # user_id 제거 (사용자별 분리 제거) - 이미 존재하지 않을 수 있음
    remove_column :trending_videos, :user_id, :integer if column_exists?(:trending_videos, :user_id)
    
    # collected_at을 collection_date로 변경 (일일 단위 관리)
    add_column :trending_videos, :collection_date, :date unless column_exists?(:trending_videos, :collection_date)
    
    # 기존 데이터가 있다면 collected_at을 기반으로 collection_date 설정
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE trending_videos 
          SET collection_date = DATE(collected_at) 
          WHERE collected_at IS NOT NULL
        SQL
      end
    end
    
    # collected_at 제거
    remove_column :trending_videos, :collected_at, :datetime if column_exists?(:trending_videos, :collected_at)
    
    # 새로운 유니크 인덱스 추가 (video_id + region_code + collection_date)
    add_index :trending_videos, [:video_id, :region_code, :collection_date], 
              unique: true, name: 'index_trending_videos_unique_daily'
              
    # collection_date에 인덱스 추가
    add_index :trending_videos, :collection_date
    
    # region_code + collection_date 복합 인덱스
    add_index :trending_videos, [:region_code, :collection_date]
  end
end
