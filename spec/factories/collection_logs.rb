FactoryBot.define do
  factory :collection_log do
    region_code { "MyString" }
    collection_type { "MyString" }
    videos_collected { 1 }
    api_calls_used { 1 }
    status { 1 }
    error_message { "MyText" }
    started_at { "2025-07-20 11:29:48" }
    completed_at { "2025-07-20 11:29:48" }
  end
end
