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

ActiveRecord::Schema[8.1].define(version: 2026_01_12_123000) do
  create_table "location_lookups", force: :cascade do |t|
    t.datetime "cached_at"
    t.string "city"
    t.datetime "created_at", null: false
    t.text "data"
    t.text "forecast_data"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "state"
    t.datetime "updated_at", null: false
    t.string "zip"
    t.index ["city", "state"], name: "index_location_lookups_on_city_and_state"
    t.index ["zip"], name: "index_location_lookups_on_zip"
  end
end
