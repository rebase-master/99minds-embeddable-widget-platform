class CreateTriggers < ActiveRecord::Migration[8.1]
  def change
    create_table :triggers do |t|
      t.references :merchant, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.references :campaign, null: false, foreign_key: true
      t.string :shopper_id, null: false
      # Denormalized at trigger creation — historical triggers survive campaign edits.
      t.jsonb :render_payload, null: false, default: {}
      # No dispatched_at / delivered_at: Action Cable is fire-and-forget,
      # at-most-once via ON CONFLICT RETURNING gate (Stage 1.4b).

      t.timestamps
    end
    # Prevents double-fire on Sidekiq retry: same (merchant, event, campaign) inserts conflict.
    add_index :triggers, [ :merchant_id, :event_id, :campaign_id ],
      unique: true,
      name: "index_triggers_on_merchant_event_campaign"
  end
end
