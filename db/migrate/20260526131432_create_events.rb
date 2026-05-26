class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.references :merchant, null: false, foreign_key: true
      t.string :shopper_id, null: false
      t.string :event_type, null: false
      t.jsonb :data, null: false, default: {}
      t.datetime :occurred_at, null: false
      t.datetime :received_at, null: false
      t.string :idempotency_key
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
