# 커스텀 액션 로드
require_relative '../../lib/rails_admin/collect_country'
require_relative '../../lib/rails_admin/collect_all'

RailsAdmin.config do |config|
  # Asset pipeline 문제 해결을 위한 설정
  config.asset_source = :importmap
  
  # Main app layout 사용
  config.main_app_name = 'YouTube Trends Admin'

  ### Popular gems integration

  ## == Devise == (개발 단계에서 인증 비활성화)
  # config.authenticate_with do
  #   warden.authenticate! scope: :admin_user
  # end
  # config.current_user_method(&:current_admin_user)

  ## == CancanCan ==
  # config.authorize_with :cancancan

  ## == Pundit ==
  # config.authorize_with :pundit

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/railsadminteam/rails_admin/wiki/Base-configuration

  ## == Gravatar integration ==
  ## To disable Gravatar integration in Navigation Bar set to false
  # config.show_gravatar = true

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app

    ## With an audit adapter, you can add:
    # history_index
    # history_show
    
    # 커스텀 수집 액션들
    collection :collect_country, :collect_all
  end
  
  # TrendingVideo 모델 설정
  config.model 'TrendingVideo' do
    list do
      field :collection_date
      field :region_code
      field :title
      field :channel_title
      field :view_count
      field :is_shorts
      field :created_at
    end
    
    show do
      field :video_id
      field :title
      field :description, :text
      field :channel_title
      field :channel_id
      field :view_count
      field :like_count
      field :comment_count
      field :published_at
      field :duration
      field :thumbnail_url
      field :is_shorts
      field :region_code
      field :collection_date
      field :created_at
      field :updated_at
    end
  end
end
