module Events
  class Ingest
    REPLAY_WINDOW = 5.minutes

    class Error < StandardError
      attr_reader :status, :code

      def initialize(status:, code:, message:)
        super(message)
        @status = status
        @code = code
      end
    end

    def self.call(merchant:, raw_body:, idempotency_key:)
      payload = JSON.parse(raw_body)
      occurred_at = Time.iso8601(payload.fetch("occurred_at"))

      if (Time.current - occurred_at).abs > REPLAY_WINDOW
        raise Error.new(status: :bad_request, code: "event.outside_replay_window",
                        message: "occurred_at outside the replay window.")
      end

      content_hash = Digest::SHA256.hexdigest(raw_body)
      now = Time.current

      result = Event.insert_all(
        [ {
          merchant_id: merchant.id,
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
        EvaluateEventJob.perform_async(event_id, merchant.id)
        event_id
      else
        existing = Event.find_by!(merchant_id: merchant.id, idempotency_key: idempotency_key)
        if existing.idempotency_content_hash != content_hash
          raise Error.new(status: :unprocessable_entity, code: "idempotency.content_mismatch",
                          message: "Idempotency-Key reused with different body.")
        end
        existing.id
      end
    rescue KeyError, ArgumentError, TypeError
      raise Error.new(status: :bad_request, code: "event.invalid_payload",
                      message: "Payload missing required fields or fields invalid.")
    end
  end
end
