class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.references :merchant, null: false, foreign_key: true
      # Merchant-supplied shopper identifier (opaque to us).
      t.string :shopper_id, null: false
      # e.g. "cart.updated", "order.placed".
      t.string :event_type, null: false
      # Free-form payload from the storefront.
      t.jsonb :data, null: false, default: {}
      # When the shopper-side event happened.
      t.datetime :occurred_at, null: false
      # When we received it (≠ created_at conceptually; same in practice).
      t.datetime :received_at, null: false
      # Opaque UUID supplied by storefront, used for ON CONFLICT dedup. App enforces presence at ingest.
      t.string :idempotency_key
      # SHA256 of raw body; same key + different body → 422 idempotency.content_mismatch.
      t.string :idempotency_content_hash

      t.timestamps
    end
    # Partial unique: forward-compatible with replay events that may carry a null idempotency_key.
    add_index :events, [ :merchant_id, :idempotency_key ],
      unique: true,
      where: "idempotency_key IS NOT NULL",
      name: "index_events_on_merchant_id_and_idempotency_key_present"
    # Replay/lookup queries: most-recent-first per shopper.
    add_index :events, [ :merchant_id, :shopper_id, :occurred_at ],
      order: { occurred_at: :desc },
      name: "index_events_on_merchant_shopper_occurred"
  end
end
