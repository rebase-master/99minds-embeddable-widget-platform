module Api
  module V1
    class EventsController < ApplicationController
      include AuthenticateMerchant

      REPLAY_WINDOW = 5.minutes

      def create
        idempotency_key = request.headers["Idempotency-Key"]
        return render_error(:bad_request, "event.idempotency_key_required", "Idempotency-Key header required.") if idempotency_key.blank?

        body = request.raw_post
        unless Authentication::VerifyHmac.call(
          merchant: ActsAsTenant.current_tenant,
          signature: request.headers["X-Signature"],
          idempotency_key: idempotency_key,
          body: body
        )
          return render_error(:unauthorized, "auth.invalid_signature", "Invalid HMAC signature.")
        end

        payload = JSON.parse(body)
        occurred_at = Time.iso8601(payload.fetch("occurred_at"))
        if (Time.current - occurred_at).abs > REPLAY_WINDOW
          return render_error(:bad_request, "event.outside_replay_window", "occurred_at outside the replay window.")
        end

        content_hash = Digest::SHA256.hexdigest(body)
        event_id = insert_or_find_event(idempotency_key, content_hash, payload, occurred_at)

        if event_id == :content_mismatch
          render_error(:unprocessable_entity, "idempotency.content_mismatch", "Idempotency-Key reused with different body.")
        else
          render json: { data: { event_id: event_id, status: "received" } }, status: :accepted
        end
      rescue JSON::ParserError
        render_error(:bad_request, "event.invalid_json", "Body is not valid JSON.")
      rescue KeyError, ArgumentError, TypeError
        render_error(:bad_request, "event.invalid_payload", "Payload missing required fields or fields invalid.")
      end

      private

      def insert_or_find_event(idempotency_key, content_hash, payload, occurred_at)
        merchant_id = ActsAsTenant.current_tenant.id
        now = Time.current

        result = Event.insert_all(
          [ {
            merchant_id: merchant_id,
            shopper_id: payload.fetch("shopper_id"),
            event_type: payload.fetch("event_type"),
            data: payload["data"] || {},
            occurred_at: occurred_at,
            received_at: now,
            idempotency_key: idempotency_key,
            idempotency_content_hash: content_hash,
            created_at: now,
            updated_at: now
          } ],
          unique_by: :index_events_on_merchant_id_and_idempotency_key_present,
          returning: [ :id ]
        )

        if (row = result.rows.first)
          event_id = row.first
          EvaluateEventJob.perform_async(event_id, merchant_id)
          event_id
        else
          existing = Event.find_by!(idempotency_key: idempotency_key)
          existing.idempotency_content_hash == content_hash ? existing.id : :content_mismatch
        end
      end

      def render_error(status, code, message)
        render json: { error: { code: code, message: message } }, status: status
      end
    end
  end
end
