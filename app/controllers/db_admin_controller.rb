class DbAdminController < ApplicationController
  # 임시 DB 관리 도구 (개발용)
  
  def index
    @tables = get_table_info
  end
  
  def table
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
      redirect_to db_admin_path, alert: "유효하지 않은 테이블입니다."
    end
  end
  
  def query
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
  
  private
  
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
end