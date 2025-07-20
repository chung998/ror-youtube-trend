require 'rails_admin/config/actions'
require 'rails_admin/config/actions/base'

module RailsAdmin
  module Config
    module Actions
      class CollectCountry < RailsAdmin::Config::Actions::Base
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
              # GET 요청: 수집 폼 표시
              @regions = %w[KR US JP GB DE FR]
              @collection_status = TrendingCollectionService.new.collection_status
              render @action.template_name
            elsif request.post?
              # POST 요청: 실제 수집 실행
              region = params[:region]&.upcase
              
              if region.blank? || !%w[KR US JP GB DE FR].include?(region)
                flash[:error] = "올바른 국가를 선택해주세요."
                redirect_to back_or_index
                return
              end
              
              service = TrendingCollectionService.new
              result = service.collect_country(region)
              
              if result[:success]
                flash[:success] = result[:message]
              else
                flash[:error] = result[:error]
              end
              
              redirect_to back_or_index
            end
          end
        end

        register_instance_option :link_icon do
          'fa fa-download'
        end

        register_instance_option :pjax? do
          false
        end
      end
    end
  end
end