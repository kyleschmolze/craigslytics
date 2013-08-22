# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130821185331) do

  create_table "analyses", :force => true do |t|
    t.float    "latitude"
    t.float    "longitude"
    t.integer  "bedrooms"
    t.integer  "price"
    t.string   "address"
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
    t.boolean  "processed",     :default => false
    t.integer  "average_price"
    t.boolean  "failed",        :default => false
    t.integer  "radius"
    t.string   "tags"
  end

  create_table "analyses_listings", :id => false, :force => true do |t|
    t.integer "analysis_id"
    t.integer "listing_id"
  end

  create_table "listing_comparisons", :force => true do |t|
    t.integer  "listing_1_id"
    t.integer  "listing_2_id"
    t.float    "score"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.integer  "duplicate",      :default => 0
    t.float    "address_score"
    t.float    "bedrooms_score"
    t.float    "location_score"
    t.float    "price_score"
  end

  create_table "listing_details", :force => true do |t|
    t.string   "source"
    t.text     "body"
    t.string   "body_type"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.integer  "user_id"
    t.string   "u_id"
    t.text     "description"
  end

  create_table "listing_importers", :force => true do |t|
    t.integer  "user_id"
    t.string   "api_key"
    t.string   "source"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "metro"
  end

  create_table "listing_imports", :force => true do |t|
    t.datetime "completed_at"
    t.integer  "listing_importer_id"
    t.integer  "new_listings",        :default => 0
    t.integer  "updated_listings",    :default => 0
    t.integer  "failed_listings",     :default => 0
    t.string   "current_anchor"
    t.datetime "current_date"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
  end

  create_table "listing_tags", :force => true do |t|
    t.integer  "listing_id"
    t.integer  "tag_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "listings", :force => true do |t|
    t.float    "latitude"
    t.float    "longitude"
    t.integer  "bedrooms"
    t.integer  "price"
    t.string   "address"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.integer  "listing_detail_id"
    t.integer  "user_id"
    t.datetime "expired_at"
    t.integer  "timestamp"
    t.string   "bathrooms"
  end

  create_table "tags", :force => true do |t|
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "display"
    t.string   "search_term"
    t.integer  "complexity"
    t.string   "name"
    t.string   "category"
    t.string   "parent"
  end

  create_table "user_inquiries", :force => true do |t|
    t.string   "email"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "",    :null => false
    t.string   "encrypted_password",     :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.boolean  "admin",                  :default => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "utility_analyses", :force => true do |t|
    t.boolean  "fresh"
    t.integer  "tag_id"
    t.integer  "listing_id"
    t.text     "listings_with"
    t.text     "listings_without"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.integer  "price_difference"
  end

end
