module Triggers
  class Dispatch
    # Fire-and-forget broadcast. Stream key must mirror TriggersChannel#subscribed.
    # Called by EvaluateEventJob only when the trigger row was newly inserted
    # (at-most-once gate, TRADEOFFS Stage 1.4b).
    def self.call(merchant_id:, shopper_id:, render_payload:)
      ActionCable.server.broadcast(
        "merchant:#{merchant_id}:shopper:#{shopper_id}",
        render_payload
      )
    end
  end
end
