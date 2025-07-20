FactoryBot.define do
  factory :trending_video do
    video_id { "MyString" }
    title { "MyText" }
    description { "MyText" }
    channel_title { "MyString" }
    channel_id { "MyString" }
    view_count { 1 }
    like_count { 1 }
    comment_count { 1 }
    published_at { "2025-07-20 11:29:41" }
    duration { "MyString" }
    thumbnail_url { "MyText" }
    region_code { "MyString" }
    is_shorts { false }
    collected_at { "2025-07-20 11:29:41" }
  end
end
