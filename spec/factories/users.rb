FactoryBot.define do
  factory :user do
    email { "MyString" }
    password_digest { "MyString" }
    admin { false }
    verified { false }
    last_sign_in_at { "2025-07-20 11:29:54" }
  end
end
