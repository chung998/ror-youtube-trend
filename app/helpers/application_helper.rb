module ApplicationHelper
  # 한글 날짜 포맷팅 (예: 3일 전, 2주 전, 1개월 전)
  def korean_time_ago(datetime)
    return '' unless datetime
    
    now = Time.current
    diff_seconds = (now - datetime).to_i
    
    case diff_seconds
    when 0...60
      "방금 전"
    when 60...3600
      minutes = diff_seconds / 60
      "#{minutes}분 전"
    when 3600...86400
      hours = diff_seconds / 3600
      "#{hours}시간 전"
    when 86400...604800
      days = diff_seconds / 86400
      "#{days}일 전"
    when 604800...2629746
      weeks = diff_seconds / 604800
      "#{weeks}주 전"
    when 2629746...31556952
      months = diff_seconds / 2629746
      "#{months}개월 전"
    else
      years = diff_seconds / 31556952
      "#{years}년 전"
    end
  end

  # YouTube 동영상 시간 포맷팅 (PT4M13S → 4분 13초)
  def format_korean_duration(duration)
    return '' unless duration.present?
    
    # ISO 8601 duration 포맷 파싱 (PT1H5M30S, PT4M13S, PT45S 등)
    match = duration.match(/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/)
    return duration unless match
    
    hours = match[1]&.to_i || 0
    minutes = match[2]&.to_i || 0
    seconds = match[3]&.to_i || 0
    
    result = []
    result << "#{hours}시간" if hours > 0
    result << "#{minutes}분" if minutes > 0
    result << "#{seconds}초" if seconds > 0
    
    result.empty? ? '0초' : result.join(' ')
  end
end
