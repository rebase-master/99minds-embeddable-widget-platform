class CreateMerchants < ActiveRecord::Migration[8.1]
  def change
    create_table :merchants do |t|
      t.string :name, null: false
      # SHA256(api_key + ENV['API_KEY_PEPPER']). Constant-time DB lookup via unique index.
      t.string :api_key_digest, null: false
      # Encrypted at rest via Rails 8 AR Encryption (`encrypts :hmac_secret` on model, Stage 1.2).
      t.string :hmac_secret, null: false
      # Public token the SDK sends with GET /v1/sdk/theme. Distinct from api_key_digest.
      t.string :sdk_public_key, null: false
      # Color tokens, fonts, labels — read on every storefront page load.
      t.jsonb :theme, null: false, default: {}
      # Monotonic counter, bumped on theme update; participates in cache key.
      t.bigint :theme_version, null: false, default: 0

      t.timestamps
    end
    add_index :merchants, :api_key_digest, unique: true
    add_index :merchants, :sdk_public_key, unique: true
  end
end
