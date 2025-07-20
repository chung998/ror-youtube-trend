class Admin::AdminController < ApplicationController
  before_action :require_admin # 실제 운영에서는 인증 구현

  def index
    # 대시보드 통계
    @collection_stats = {
      today_collections: collection_logs_today.count,
      successful_today: collection_logs_successful_today.count,
      failed_today: collection_logs_failed_today.count,
      total_videos: TrendingVideo.count
    }
    
    # 다음 예정된 수집 시간 (임시로 다음 6시간 후로 설정)
    @next_scheduled = Time.current.beginning_of_hour + 6.hours
    
    # 최근 수집 로그
    @recent_logs = recent_collection_logs
    
    # 실패한 수집 작업
    @failed_collections = failed_collection_logs
  end

  def collection_logs
    @collection_logs = CollectionLog.order(started_at: :desc)
                                   .page(params[:page])
                                   .per(20)
  end

  # DB 관리 기능들을 통합
  def database
    @tables = get_table_info
  end

  def database_table
    @table_name = params[:table]
    @page = params[:page]&.to_i || 1
    @per_page = 50
    @offset = (@page - 1) * @per_page
    
    if valid_table?(@table_name)
      @columns = get_table_columns(@table_name)
      @rows = get_table_data(@table_name)
      @total_count = get_table_count(@table_name)
      @total_pages = (@total_count.to_f / @per_page).ceil
    else
      redirect_to admin_database_path, alert: "유효하지 않은 테이블입니다."
    end
  end

  def database_query
    @sql = params[:sql]
    @results = []
    @error = nil
    
    if @sql.present?
      begin
        # 안전한 읽기 전용 쿼리만 허용
        if safe_query?(@sql)
          @results = ActiveRecord::Base.connection.exec_query(@sql)
        else
          @error = "읽기 전용 쿼리(SELECT)만 허용됩니다."
        end
      rescue => e
        @error = e.message
      end
    end
  end

  # 수동 수집 기능
  def collect_now
    region = params[:region]
    collection_type = params[:type] || 'all'
    
    if valid_region?(region)
      # 백그라운드 잡으로 수집 시작
      CollectTrendingDataJob.perform_later(region, collection_type)
      redirect_to admin_path, notice: "#{region} 지역 데이터 수집을 시작했습니다."
    else
      redirect_to admin_path, alert: "유효하지 않은 지역 코드입니다."
    end
  end

  private

  def require_admin
    # 개발 환경에서는 체크 안함
    return if Rails.env.development?
    
    # 실제 운영에서는 여기에 관리자 인증 로직 구현
    # redirect_to root_path unless current_user&.admin?
  end

  def valid_region?(region_code)
    %w[KR US JP GB DE FR IN BR MX CA AU].include?(region_code)
  end

  # DB 관리용 메서드들
  def get_table_info
    tables = ActiveRecord::Base.connection.tables
    tables.map do |table|
      count = ActiveRecord::Base.connection.exec_query("SELECT COUNT(*) as count FROM #{table}").first['count']
      { name: table, count: count }
    end
  end
  
  def get_table_columns(table_name)
    ActiveRecord::Base.connection.columns(table_name)
  end
  
  def get_table_data(table_name)
    ActiveRecord::Base.connection.exec_query(
      "SELECT * FROM #{table_name} ORDER BY id DESC LIMIT #{@per_page} OFFSET #{@offset}"
    )
  end
  
  def get_table_count(table_name)
    ActiveRecord::Base.connection.exec_query("SELECT COUNT(*) as count FROM #{table_name}").first['count']
  end
  
  def valid_table?(table_name)
    ActiveRecord::Base.connection.tables.include?(table_name)
  end
  
  def safe_query?(sql)
    sql.strip.downcase.start_with?('select') && 
    !sql.downcase.include?('delete') && 
    !sql.downcase.include?('update') && 
    !sql.downcase.include?('insert') && 
    !sql.downcase.include?('drop') && 
    !sql.downcase.include?('alter')
  end

  # 컬렉션 로그 헬퍼 메서드들
  def collection_logs_today
    return [] unless defined?(CollectionLog)
    CollectionLog.where(started_at: Date.current.beginning_of_day..Date.current.end_of_day)
  end

  def collection_logs_successful_today
    return [] unless defined?(CollectionLog)
    logs = collection_logs_today
    return logs if logs.respond_to?(:completed)
    logs.select { |log| log.status == 'completed' }
  end

  def collection_logs_failed_today
    return [] unless defined?(CollectionLog)
    logs = collection_logs_today
    return logs if logs.respond_to?(:failed)
    logs.select { |log| log.status == 'failed' }
  end

  def recent_collection_logs
    return [] unless defined?(CollectionLog)
    CollectionLog.order(started_at: :desc).limit(10)
  end

  def failed_collection_logs
    return [] unless defined?(CollectionLog)
    CollectionLog.where(status: 'failed').order(started_at: :desc).limit(5)
  end
end