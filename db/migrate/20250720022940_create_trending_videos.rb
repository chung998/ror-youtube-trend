class CreateTrendingVideos < ActiveRecord::Migration[8.0]
  def change
    create_table :trending_videos do |t|
      t.string :video_id, null: false, limit: 11
      t.text :title, null: false
      t.text :description
      t.string :channel_title, null: false
      t.string :channel_id, null: false, limit: 24
      t.integer :view_count, limit: 8, default: 0  # bigint
      t.integer :like_count, limit: 8, default: 0  # bigint
      t.integer :comment_count, limit: 8, default: 0  # bigint
      t.datetime :published_at, null: false
      t.string :duration, limit: 20
      t.text :thumbnail_url
      t.string :region_code, null: false, limit: 2
      t.boolean :is_shorts, default: false
      t.datetime :collected_at, null: false
      t.references :user, foreign_key: true, null: true

      t.timestamps
    end

    # 인덱스 추가
    add_index :trending_videos, [:region_code, :collected_at]
    add_index :trending_videos, [:is_shorts, :view_count]
    add_index :trending_videos, :published_at
    add_index :trending_videos, :view_count
    
    # 중복 방지 유니크 인덱스
    add_index :trending_videos, [:video_id, :region_code, :collected_at], 
              unique: true, name: 'unique_video_region_date'
  end
end
