service = YoutubeDataService.new
begin
  puts '=== 데이터베이스 저장 테스트 ==='
  videos_data = service.fetch_trending_videos('KR', 'all', 3)
  
  saved_count = 0
  videos_data.each do |video_data|
    begin
      video = TrendingVideo.create!(
        video_id: video_data[:video_id],
        title: video_data[:title],
        description: video_data[:description],
        channel_title: video_data[:channel_title],
        channel_id: video_data[:channel_id],
        view_count: video_data[:view_count],
        like_count: video_data[:like_count],
        comment_count: video_data[:comment_count],
        published_at: video_data[:published_at],
        duration: video_data[:duration],
        thumbnail_url: video_data[:thumbnail_url],
        region_code: 'KR',
        is_shorts: video_data[:is_shorts],
        collected_at: video_data[:collected_at]
      )
      saved_count += 1
      puts "저장 성공: #{video.title[0..50]}..."
    rescue ActiveRecord::RecordNotUnique
      puts "중복 데이터 건너뜀: #{video_data[:title][0..50]}..."
    rescue => e
      puts "저장 실패: #{e.message}"
    end
  end
  
  puts "=== 결과: #{saved_count}개 저장 완료 ==="
  puts "총 저장된 비디오 수: #{TrendingVideo.count}"
rescue => e
  puts "에러: #{e.message}"
end