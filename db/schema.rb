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

ActiveRecord::Schema.define(:version => 20130614142954) do

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

  create_table "listings", :force => true do |t|
    t.float    "latitude"
    t.float    "longitude"
    t.integer  "bedrooms"
    t.integer  "price"
    t.string   "address"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.text     "info"
    t.boolean  "dogs"
    t.boolean  "cats"
    t.text     "body"
  end

  create_table "tags", :force => true do |t|
    t.integer  "listing_id"
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

end
