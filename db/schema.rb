# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_20_190000) do
  create_table "collection_logs", force: :cascade do |t|
    t.string "region_code", limit: 2, null: false
    t.string "collection_type", default: "all", null: false
    t.integer "videos_collected", default: 0
    t.integer "api_calls_used", default: 0
    t.integer "status", default: 0
    t.text "error_message"
    t.datetime "started_at", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["region_code", "created_at"], name: "index_collection_logs_on_region_code_and_created_at"
    t.index ["started_at"], name: "index_collection_logs_on_started_at"
    t.index ["status"], name: "index_collection_logs_on_status"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "trending_videos", force: :cascade do |t|
    t.string "video_id", limit: 11, null: false
    t.text "title", null: false
    t.text "description"
    t.string "channel_title", null: false
    t.string "channel_id", limit: 24, null: false
    t.integer "view_count", limit: 8, default: 0
    t.integer "like_count", limit: 8, default: 0
    t.integer "comment_count", limit: 8, default: 0
    t.datetime "published_at", null: false
    t.string "duration", limit: 20
    t.text "thumbnail_url"
    t.string "region_code", limit: 2, null: false
    t.boolean "is_shorts", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "collection_date"
    t.index ["collection_date"], name: "index_trending_videos_on_collection_date"
    t.index ["is_shorts", "view_count"], name: "index_trending_videos_on_is_shorts_and_view_count"
    t.index ["published_at"], name: "index_trending_videos_on_published_at"
    t.index ["region_code", "collection_date"], name: "index_trending_videos_on_region_code_and_collection_date"
    t.index ["region_code"], name: "index_trending_videos_on_region_code_and_collected_at"
    t.index ["video_id", "region_code", "collection_date"], name: "index_trending_videos_unique_daily", unique: true
    t.index ["video_id", "region_code"], name: "unique_video_region_date", unique: true
    t.index ["view_count"], name: "index_trending_videos_on_view_count"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "user"
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "active"
    t.datetime "last_login_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["last_login_at"], name: "index_users_on_last_login_at"
    t.index ["status"], name: "index_users_on_status"
  end

  add_foreign_key "sessions", "users"
end
