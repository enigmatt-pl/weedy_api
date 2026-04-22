class InitialSchema < ActiveRecord::Migration[7.1]
  def change
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    execute <<-SQL
      CREATE OR REPLACE FUNCTION uuid_generate_v7()
      RETURNS uuid
      AS $$
      DECLARE
        v_time timestamp with time zone := clock_timestamp();
        v_giga_ms bigint := floor(extract(epoch from v_time) * 1000);
        v_bytes bytea;
      BEGIN
        v_bytes := decode(lpad(to_hex(v_giga_ms), 12, '0'), 'hex') || gen_random_bytes(10);
        v_bytes := set_byte(v_bytes, 6, (get_byte(v_bytes, 6) & 15) | 112);
        v_bytes := set_byte(v_bytes, 8, (get_byte(v_bytes, 8) & 63) | 128);
        RETURN encode(v_bytes, 'hex')::uuid;
      END
      $$ LANGUAGE plpgsql VOLATILE;
    SQL

    create_table "users", id: :uuid, default: -> { "uuid_generate_v7()" } do |t|
      t.string "email", default: "", null: false
      t.string "encrypted_password", default: "", null: false
      t.string "reset_password_token"
      t.datetime "reset_password_sent_at"
      t.datetime "remember_created_at"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "first_name"
      t.string "last_name"
      t.string "avatar_url"
      t.string "city"
      t.string "postcode"
      t.string "province"
      t.string "allegro_auth_state"
      t.datetime "accepted_terms_at"
      t.datetime "accepted_privacy_at"
      t.string "legal_version"
      t.integer "role", default: 0
      t.boolean "approved", default: false
      t.integer "credits", default: 0, null: false
      t.index ["email"], name: "index_users_on_email", unique: true
      t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    end

    create_table "listings", id: :uuid, default: -> { "uuid_generate_v7()" } do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.string "title", null: false
      t.text "description"
      t.decimal "estimated_price", precision: 10, scale: 2, default: 0.0, null: false
      t.integer "status", default: 0, null: false
      t.string "oem_number"
      t.string "allegro_offer_id"
      t.jsonb "image_urls", default: []
      t.text "query_data"
      t.jsonb "market_data", default: {}
      t.string "allegro_product_id"
      t.string "allegro_category_id"
      t.text "reasoning"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false

      t.index ["oem_number"]
      t.index ["status"]
      t.index ["created_at"]
    end

    create_table "allegro_integrations", id: :uuid, default: -> { "uuid_generate_v7()" } do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true, index: { unique: true }
      t.text "access_token"
      t.text "refresh_token"
      t.datetime "expires_at"
      t.string "client_id"
      t.text "client_secret"
      t.string "auth_state"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "active_storage_blobs", id: :uuid, default: -> { "uuid_generate_v7()" } do |t|
      t.string   "key",          null: false
      t.string   "filename",     null: false
      t.string   "content_type"
      t.text     "metadata"
      t.string   "service_name", null: false
      t.bigint   "byte_size",    null: false
      t.string   "checksum"
      t.datetime "created_at", precision: 6, null: false
      t.index [ "key" ], unique: true
    end

    create_table "active_storage_attachments", id: :uuid, default: -> { "uuid_generate_v7()" } do |t|
      t.string     "name",     null: false
      t.references "record",   null: false, polymorphic: true, index: false, type: :uuid
      t.references "blob",     null: false, type: :uuid
      t.datetime "created_at", precision: 6, null: false
      t.index [ :record_type, :record_id, :name, :blob_id ], name: "index_active_storage_attachments_uniqueness", unique: true
      t.foreign_key "active_storage_blobs", column: "blob_id"
    end

    create_table "active_storage_variant_records", id: :uuid, default: -> { "uuid_generate_v7()" } do |t|
      t.references "blob", null: false, index: false, type: :uuid
      t.string "variation_digest", null: false
      t.index [ :blob_id, :variation_digest ], name: "index_active_storage_variant_records_uniqueness", unique: true
      t.foreign_key "active_storage_blobs", column: "blob_id"
    end
  end
end
