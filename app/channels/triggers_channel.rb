class TriggersChannel < ApplicationCable::Channel
  # Stream key is namespaced with merchant_id from the connection identifier set
  # by JWT decode in ApplicationCable::Connection — never from params or current_tenant
  # (CLAUDE.md tenant audit §6: per-action context resets inside channels).
  def subscribed
    stream_from "merchant:#{merchant_id}:shopper:#{shopper_id}"
  end
end
