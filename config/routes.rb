Rails.application.routes.draw do
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
  get 'search', to: 'trending#search'
  post 'collect_now', to: 'trending#collect_now'
  
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
    root 'dashboard#index'
    get 'collection_logs', to: 'dashboard#collection_logs'
  end
  
  # 헬스체크
  get 'health', to: 'health#show'
  
  # Rails 기본 헬스체크
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
