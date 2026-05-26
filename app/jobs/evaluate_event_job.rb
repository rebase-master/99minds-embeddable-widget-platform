class EvaluateEventJob
  include Sidekiq::Job

  # Filled in Stage 1.4. Tenant is threaded via acts_as_tenant Sidekiq middleware;
  # merchant_id is also passed explicitly per CLAUDE.md tenant audit §5.
  def perform(event_id, merchant_id)
    # no-op
  end
end
