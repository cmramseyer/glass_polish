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

ActiveRecord::Schema[8.1].define(version: 2026_09_10_230241) do
  create_table "polish_trackings", force: :cascade do |t|
    t.integer "available"
    t.integer "completed"
    t.datetime "created_at", null: false
    t.string "customer"
    t.integer "height"
    t.integer "order_id"
    t.string "polish_type"
    t.string "product"
    t.integer "total_item"
    t.integer "tracking_id"
    t.datetime "updated_at", null: false
    t.integer "width"
  end

  create_table "processed_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_id", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_processed_events_on_event_id", unique: true
  end
end
