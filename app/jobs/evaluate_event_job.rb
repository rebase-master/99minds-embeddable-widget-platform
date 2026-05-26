class EvaluateEventJob
  include Sidekiq::Job

  sidekiq_options retry: 5

  def perform(event_id, merchant_id)
    ActsAsTenant.with_tenant(Merchant.find(merchant_id)) do
      event = Event.find(event_id)
      Campaign.where(event_type: event.event_type, active: true).find_each do |campaign|
        next unless ConditionEvaluator.match?(campaign.conditions, event.data)

        now = Time.current
        result = Trigger.insert_all(
          [ {
            merchant_id: merchant_id,
            event_id: event.id,
            campaign_id: campaign.id,
            shopper_id: event.shopper_id,
            render_payload: campaign.render,
            created_at: now,
            updated_at: now
          } ],
          unique_by: :index_triggers_on_merchant_event_campaign,
          returning: [ :id ]
        )

        # At-most-once gate (TRADEOFFS.md Stage 1.4b): dispatch only when the insert
        # produced a new row. Conflict → already evaluated → skip silently.
        next unless result.rows.first
        # Triggers::Dispatch.call(result.rows.first.first) — wired in Stage 1.6.
      end
    end
  end
end
