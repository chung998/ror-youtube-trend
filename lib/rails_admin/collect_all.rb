require 'rails_admin/config/actions'
require 'rails_admin/config/actions/base'

module RailsAdmin
  module Config
    module Actions
      class CollectAll < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :collection do
          true
        end

        register_instance_option :http_methods do
          [:get, :post]
        end

        register_instance_option :controller do
          proc do
            if request.get?
              # GET 요청: 확인 페이지 표시
              @collection_status = TrendingCollectionService.new.collection_status
              render @action.template_name
            elsif request.post?
              # POST 요청: 전체 국가 수집 실행
              service = TrendingCollectionService.new
              result = service.collect_all_countries
              
              if result[:success]
                flash[:success] = result[:message]
              else
                failed_countries = result[:results].select { |r| !r[:success] }
                error_messages = failed_countries.map { |r| "#{r[:region]}: #{r[:error]}" }
                flash[:error] = "일부 국가 수집 실패: #{error_messages.join(', ')}"
              end
              
              redirect_to back_or_index
            end
          end
        end

        register_instance_option :link_icon do
          'fa fa-globe'
        end

        register_instance_option :pjax? do
          false
        end
      end
    end
  end
end