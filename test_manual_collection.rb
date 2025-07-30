#!/usr/bin/env ruby
# 수동 수집 테스트 스크립트

puts "🚀 수동 수집 테스트 시작..."
puts "현재 시간: #{Time.current} (#{Time.zone})"
puts "=" * 50

# Rails 환경 로드
require_relative 'config/environment'

puts "📊 기존 데이터 확인..."
before_count = TrendingVideo.count
puts "기존 영상 개수: #{before_count}개"

puts "\n🔄 CollectAllCountriesJob 수동 실행..."
begin
  result = CollectAllCountriesJob.perform_now
  puts "✅ 수집 완료! 수집된 영상: #{result}개"
rescue => e
  puts "❌ 수집 실패: #{e.message}"
  puts e.backtrace.first(5)
  exit 1
end

puts "\n📈 수집 후 데이터 확인..."
after_count = TrendingVideo.count
puts "수집 후 영상 개수: #{after_count}개"
puts "새로 추가된 영상: #{after_count - before_count}개"

puts "\n🌍 지역별 분포:"
%w[KR US JP GB DE FR VN ID].each do |region|
  count = TrendingVideo.by_region(region).count
  puts "#{region}: #{count}개"
end

puts "\n📅 최근 수집 시간:"
latest = TrendingVideo.order(:created_at).last
if latest
  puts "마지막 수집: #{latest.created_at} (#{latest.region_code})"
else
  puts "수집된 데이터 없음"
end

puts "\n🎯 메가히트 영상:"
mega_hits = TrendingVideo.mega_hits.limit(3)
if mega_hits.any?
  mega_hits.each do |video|
    puts "- #{video.title[0..30]}... (#{video.formatted_view_count}, #{video.region_code})"
  end
else
  puts "메가히트 영상 없음"
end

puts "\n✨ 테스트 완료!" 