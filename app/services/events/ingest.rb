module Events
  class Ingest
    REPLAY_WINDOW = 5.minutes
    # ISO8601 strings must carry Z or ±HH:MM (or ±HHMM) offset. Naive timestamps would be
    # parsed against the server's TZ and silently mis-skew the replay window.
    ISO8601_WITH_OFFSET = /(?:Z|[+-]\d{2}:?\d{2})\z/

    def self.call(merchant:, raw_body:, idempotency_key:)
      payload = JSON.parse(raw_body)

      shopper_id = require_nonblank_string(payload, "shopper_id")
      event_type = require_nonblank_string(payload, "event_type")
      occurred_at_str = require_nonblank_string(payload, "occurred_at")
      unless occurred_at_str.match?(ISO8601_WITH_OFFSET)
        raise invalid_payload("occurred_at must include a timezone designator (Z or ±HH:MM).")
      end
      data = payload.fetch("data", {})
      raise invalid_payload("data must be a JSON object.") unless data.is_a?(Hash)

      occurred_at = Time.iso8601(occurred_at_str)
      if (Time.current - occurred_at).abs > REPLAY_WINDOW
        raise ApiError.new(status: :bad_request, code: "event.outside_replay_window",
                           message: "occurred_at outside the replay window.")
      end

      content_hash = Digest::SHA256.hexdigest(raw_body)
      now = Time.current

      result = Event.insert_all(
        [ {
          merchant_id: merchant.id,
          shopper_id: shopper_id,
          event_type: event_type,
          data: data,
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
        EvaluateEventJob.perform_async(event_id, merchant.id)
        event_id
      else
        existing = Event.find_by(merchant_id: merchant.id, idempotency_key: idempotency_key)
        unless existing
          raise ApiError.new(status: :internal_server_error, code: "event.dedup_invariant_breach",
                             message: "Idempotency conflict reported but no matching row found.")
        end
        if existing.idempotency_content_hash != content_hash
          raise ApiError.new(status: :unprocessable_entity, code: "idempotency.content_mismatch",
                             message: "Idempotency-Key reused with different body.")
        end
        existing.id
      end
    rescue KeyError, ArgumentError, TypeError
      raise invalid_payload("Payload missing required fields or fields invalid.")
    end

    def self.require_nonblank_string(payload, key)
      value = payload.fetch(key)
      raise invalid_payload("#{key} must be a non-empty string.") unless value.is_a?(String) && !value.empty?
      value
    end
    private_class_method :require_nonblank_string

    def self.invalid_payload(message)
      ApiError.new(status: :bad_request, code: "event.invalid_payload", message: message)
    end
    private_class_method :invalid_payload
  end
end
