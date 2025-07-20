require 'rails_helper'

RSpec.describe "Trendings", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/trending/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /search" do
    it "returns http success" do
      get "/trending/search"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /collect_now" do
    it "returns http success" do
      get "/trending/collect_now"
      expect(response).to have_http_status(:success)
    end
  end

end
