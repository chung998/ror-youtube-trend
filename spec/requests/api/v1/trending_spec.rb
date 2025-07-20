require 'rails_helper'

RSpec.describe "Api::V1::Trendings", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/v1/trending/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /search" do
    it "returns http success" do
      get "/api/v1/trending/search"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /collect" do
    it "returns http success" do
      get "/api/v1/trending/collect"
      expect(response).to have_http_status(:success)
    end
  end

end
