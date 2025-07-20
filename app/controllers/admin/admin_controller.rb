class Admin::AdminController < ApplicationController
  before_action :require_admin # 실제 운영에서는 인증 구현
  
  # 관리자 페이지에서 제외할 시스템 테이블들
  EXCLUDED_TABLES = %w[
    ar_internal_metadata
    schema_migrations
    solid_cable_messages
    solid_cache_entries
    solid_queue_blocked_executions
    solid_queue_claimed_executions
    solid_queue_failed_executions
    solid_queue_jobs
    solid_queue_paused_executions
    solid_queue_processes
    solid_queue_ready_executions
    solid_queue_recurring_executions
    solid_queue_scheduled_executions
    solid_queue_semaphores
  ].freeze

  def index
    # 대시보드 통계
    @collection_stats = {
      today_collections: collection_logs_today.count,
      successful_today: collection_logs_successful_today.count,
      failed_today: collection_logs_failed_today.count,
      total_videos: TrendingVideo.count
    }
    
    # 수동 수집만 가능 (자동 스케줄링 비활성화)
    @next_scheduled = nil
    
    # 최근 수집 로그
    @recent_logs = recent_collection_logs
    
    # 실패한 수집 작업
    @failed_collections = failed_collection_logs
    
    # 테이블 정보 (데이터베이스 탭에서 사용)
    @table_info = get_table_info
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
  
  # 전체 국가 수집 기능
  def collect_all
    # 등록된 모든 국가 코드
    all_regions = %w[KR US JP GB DE FR VN ID]
    
    begin
      # 각 국가를 순차적으로 수집 (API 할당량 고려하여 30초씩 간격)
      all_regions.each_with_index do |region, index|
        CollectTrendingDataJob.set(wait: index * 30.seconds)
                             .perform_later(region, 'all')
      end
      
      redirect_to admin_path, notice: "전체 #{all_regions.length}개국 데이터 수집을 시작했습니다. 완료까지 약 #{(all_regions.length * 0.5).round}분 소요됩니다."
    rescue => e
      Rails.logger.error "전체 수집 실패: #{e.message}"
      redirect_to admin_path, alert: "전체 수집 시작에 실패했습니다: #{e.message}"
    end
  end

  # DB 관리용 메서드들 (뷰에서 사용하므로 public)
  def get_table_info
    tables = ActiveRecord::Base.connection.tables
    filtered_tables = tables.reject { |table| EXCLUDED_TABLES.include?(table) }
    
    filtered_tables.map do |table|
      count = ActiveRecord::Base.connection.exec_query("SELECT COUNT(*) as count FROM #{table}").first['count']
      { name: table, count: count }
    end
  end
  
  def get_table_columns(table_name)
    ActiveRecord::Base.connection.columns(table_name)
  end
  
  def get_table_data(table_name)
    # 테이블의 컬럼을 확인하여 적절한 정렬 기준 선택
    columns = ActiveRecord::Base.connection.columns(table_name)
    
    # id 컬럼이 있으면 id로 정렬, 없으면 첫 번째 컬럼으로 정렬
    order_column = if columns.any? { |col| col.name == 'id' }
                     'id DESC'
                   elsif columns.any?
                     "#{columns.first.name} ASC"
                   else
                     ''
                   end
    
    order_clause = order_column.present? ? "ORDER BY #{order_column}" : ""
    
    ActiveRecord::Base.connection.exec_query(
      "SELECT * FROM #{table_name} #{order_clause} LIMIT #{@per_page} OFFSET #{@offset}"
    )
  end
  
  def get_table_count(table_name)
    ActiveRecord::Base.connection.exec_query("SELECT COUNT(*) as count FROM #{table_name}").first['count']
  end

  private

  def require_admin
    # 세션 기반 관리자 인증
    unless user_signed_in? && current_user.admin?
      redirect_to login_path, alert: '관리자 권한이 필요합니다.'
    end
  end

  def valid_region?(region_code)
    %w[KR US JP GB DE FR IN BR MX CA AU VN ID].include?(region_code)
  end


  
  def valid_table?(table_name)
    ActiveRecord::Base.connection.tables.include?(table_name) && 
    !EXCLUDED_TABLES.include?(table_name)
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