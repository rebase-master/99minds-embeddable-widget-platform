class CreateCampaigns < ActiveRecord::Migration[8.1]
  def change
    create_table :campaigns do |t|
      t.references :merchant, null: false, foreign_key: true
      t.string :name, null: false
      t.boolean :active, null: false, default: true
      t.string :event_type, null: false
      t.jsonb :conditions, null: false, default: []
      t.jsonb :render, null: false, default: {}

      t.timestamps
    end
    # Hot path: EvaluateEventJob filters by (merchant, event_type, active=true).
    add_index :campaigns, [ :merchant_id, :event_type ],
      where: "active = true",
      name: "index_campaigns_on_merchant_event_type_active"
  end
end
