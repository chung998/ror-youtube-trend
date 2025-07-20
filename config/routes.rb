Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  # devise_for :admin_users  # 개발 단계에서 비활성화
  namespace :api do
    namespace :v1 do
      get "trending/index"
      get "trending/search"
      get "trending/collect"
    end
  end
  root 'trending#index'
  
  # 트렌드 데이터
  get 'trending', to: 'trending#index'
  
  # 검색 페이지
  get 'search', to: 'search#index', as: 'search'
  get 'search/results', to: 'search#results', as: 'search_results'
  # 새로운 수집 액션들
  post 'trending/collect_country/:region', to: 'trending#collect_country', as: 'collect_country'
  post 'trending/collect_all', to: 'trending#collect_all_countries', as: 'collect_all_countries'
  
  # API 엔드포인트
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :trending, only: [:index] do
        collection do
          get :search
          post :collect
        end
      end
    end
  end
  
  # 관리자 페이지
  namespace :admin do
    root 'admin#index'
    get 'collection_logs', to: 'admin#collection_logs'
    get 'database', to: 'admin#database'
    get 'database/table', to: 'admin#database_table'
    get 'database/query', to: 'admin#database_query'
    post 'collect_now', to: 'admin#collect_now'
  end
  
  # DB 관리 도구 (개발용)
  get 'db_admin', to: 'db_admin#index'
  get 'db_admin/table', to: 'db_admin#table'
  get 'db_admin/query', to: 'db_admin#query'
  
  # 헬스체크
  get 'health', to: 'health#show'
  
  # Rails 기본 헬스체크
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
