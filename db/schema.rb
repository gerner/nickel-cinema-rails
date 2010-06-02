# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100602002831) do

  create_table "movies", :force => true do |t|
    t.string   "title"
    t.string   "netflix_ref_url"
    t.string   "netflix_info_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "generic_rating"
  end

  create_table "showtimes", :force => true do |t|
    t.integer  "movie_id"
    t.integer  "theater_id"
    t.datetime "showtime"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "showtimes", ["showtime"], :name => "index_showtimes_on_showtime"

  create_table "showtimes_for_zipcodes", :force => true do |t|
    t.integer  "showtime_id"
    t.integer  "zipcode"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "showtimes_for_zipcodes", ["showtime_id"], :name => "index_showtimes_for_zipcodes_on_showtime_id"
  add_index "showtimes_for_zipcodes", ["zipcode"], :name => "index_showtimes_for_zipcodes_on_zipcode"

  create_table "theaters", :force => true do |t|
    t.string   "name"
    t.string   "phone_number"
    t.string   "address"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "zipcode"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "password"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "netflix_token"
    t.string   "netflix_token_secret"
    t.string   "netflix_user_id"
  end

end
