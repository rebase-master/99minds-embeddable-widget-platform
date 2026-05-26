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

ActiveRecord::Schema[8.1].define(version: 2026_05_26_131434) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "campaigns", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.jsonb "conditions", default: [], null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.bigint "merchant_id", null: false
    t.string "name", null: false
    t.jsonb "render", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["merchant_id", "event_type"], name: "index_campaigns_on_merchant_event_type_active", where: "(active = true)"
    t.index ["merchant_id"], name: "index_campaigns_on_merchant_id"
  end

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}, null: false
    t.string "event_type", null: false
    t.string "idempotency_content_hash"
    t.string "idempotency_key"
    t.bigint "merchant_id", null: false
    t.datetime "occurred_at", null: false
    t.datetime "received_at", null: false
    t.string "shopper_id", null: false
    t.datetime "updated_at", null: false
    t.index ["merchant_id", "idempotency_key"], name: "index_events_on_merchant_id_and_idempotency_key_present", unique: true, where: "(idempotency_key IS NOT NULL)"
    t.index ["merchant_id", "shopper_id", "occurred_at"], name: "index_events_on_merchant_shopper_occurred", order: { occurred_at: :desc }
    t.index ["merchant_id"], name: "index_events_on_merchant_id"
  end

  create_table "merchants", force: :cascade do |t|
    t.string "api_key_digest", null: false
    t.datetime "created_at", null: false
    t.string "hmac_secret", null: false
    t.string "name", null: false
    t.string "sdk_public_key", null: false
    t.jsonb "theme", default: {}, null: false
    t.bigint "theme_version", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["api_key_digest"], name: "index_merchants_on_api_key_digest", unique: true
    t.index ["sdk_public_key"], name: "index_merchants_on_sdk_public_key", unique: true
  end

  create_table "triggers", force: :cascade do |t|
    t.bigint "campaign_id", null: false
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.bigint "merchant_id", null: false
    t.jsonb "render_payload", default: {}, null: false
    t.string "shopper_id", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id"], name: "index_triggers_on_campaign_id"
    t.index ["event_id"], name: "index_triggers_on_event_id"
    t.index ["merchant_id", "event_id", "campaign_id"], name: "index_triggers_on_merchant_event_campaign", unique: true
    t.index ["merchant_id"], name: "index_triggers_on_merchant_id"
  end

  add_foreign_key "campaigns", "merchants"
  add_foreign_key "events", "merchants"
  add_foreign_key "triggers", "campaigns"
  add_foreign_key "triggers", "events"
  add_foreign_key "triggers", "merchants"
end
