module Api
  module V1
    class EventsController < ApplicationController
      include AuthenticateMerchant

      def create
        idempotency_key = request.headers["Idempotency-Key"]
        if idempotency_key.blank?
          return render_api_error(status: :bad_request, code: "event.idempotency_key_required",
                                  message: "Idempotency-Key header required.")
        end

        body = request.raw_post
        unless Authentication::VerifyHmac.call(
          merchant: ActsAsTenant.current_tenant,
          signature: request.headers["X-Signature"],
          idempotency_key: idempotency_key,
          body: body
        )
          return render_api_error(status: :unauthorized, code: "auth.invalid_signature",
                                  message: "Invalid HMAC signature.")
        end

        event_id = Events::Ingest.call(
          merchant: ActsAsTenant.current_tenant,
          raw_body: body,
          idempotency_key: idempotency_key
        )

        render json: { data: { event_id: event_id, status: "received" } }, status: :accepted
      end
    end
  end
end
