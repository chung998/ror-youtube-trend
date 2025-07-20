require 'rails_helper'

RSpec.describe "Admin::Dashboards", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/admin/dashboard/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /collection_logs" do
    it "returns http success" do
      get "/admin/dashboard/collection_logs"
      expect(response).to have_http_status(:success)
    end
  end

end
