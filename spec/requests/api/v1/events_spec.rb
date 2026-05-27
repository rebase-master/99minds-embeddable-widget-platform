require "rails_helper"

RSpec.describe "POST /v1/events", type: :request do
  let(:raw_api_key) { "mk_test_events_key" }
  let(:merchant)    { create(:merchant, raw_api_key: raw_api_key) }
  let(:idem_key)    { SecureRandom.uuid }
  let(:occurred_at) { Time.current.utc.iso8601 }
  let(:body) do
    JSON.generate(
      "shopper_id"   => "shp_test",
      "event_type"   => "cart.updated",
      "occurred_at"  => occurred_at,
      "data"         => { "cart_total_cents" => 5000, "currency" => "USD" }
    )
  end
  let(:headers) { event_headers(raw_api_key, merchant, idem_key, body) }

  before { allow(EvaluateEventJob).to receive(:perform_async) }

  # ─── Happy path ───────────────────────────────────────────────────────────

  it "returns 202 and an event_id" do
    post "/v1/events", params: body, headers: headers
    expect(response).to have_http_status(:accepted)
    data = JSON.parse(response.body)["data"]
    expect(data["status"]).to eq("received")
    expect(data["event_id"]).to be_present
  end

  it "enqueues EvaluateEventJob" do
    post "/v1/events", params: body, headers: headers
    expect(EvaluateEventJob).to have_received(:perform_async)
  end

  # ─── Idempotency ──────────────────────────────────────────────────────────

  it "returns the same event_id on replay" do
    post "/v1/events", params: body, headers: headers
    first_id = JSON.parse(response.body)["data"]["event_id"]

    post "/v1/events", params: body, headers: headers
    expect(response).to have_http_status(:accepted)
    expect(JSON.parse(response.body)["data"]["event_id"]).to eq(first_id)
  end

  it "does not enqueue job on replay" do
    post "/v1/events", params: body, headers: headers
    post "/v1/events", params: body, headers: headers
    expect(EvaluateEventJob).to have_received(:perform_async).once
  end

  context "same Idempotency-Key, different body" do
    let(:other_body) do
      JSON.generate(
        "shopper_id"  => "shp_test",
        "event_type"  => "cart.updated",
        "occurred_at" => occurred_at,
        "data"        => { "cart_total_cents" => 9999, "currency" => "USD" }
      )
    end

    it "returns 422 idempotency.content_mismatch" do
      post "/v1/events", params: body, headers: headers
      # Second request: same idem_key, different body, recomputed signature
      other_headers = event_headers(raw_api_key, merchant, idem_key, other_body)
      post "/v1/events", params: other_body, headers: other_headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]["code"]).to eq("idempotency.content_mismatch")
    end
  end

  # ─── Replay window ────────────────────────────────────────────────────────

  context "occurred_at outside replay window" do
    let(:occurred_at) { (Time.current - 10.minutes).utc.iso8601 }

    it "returns 400 event.outside_replay_window" do
      post "/v1/events", params: body, headers: headers
      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)["error"]["code"]).to eq("event.outside_replay_window")
    end
  end

  # ─── Invalid payload ──────────────────────────────────────────────────────

  context "body is a JSON scalar (not an object)" do
    let(:body) { '"Hi"' }

    it "returns 400 event.invalid_payload" do
      post "/v1/events", params: body, headers: headers
      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)["error"]["code"]).to eq("event.invalid_payload")
    end
  end

  context "data is not a hash" do
    let(:body) do
      JSON.generate(
        "shopper_id"  => "shp_test",
        "event_type"  => "cart.updated",
        "occurred_at" => occurred_at,
        "data"        => "not an object"
      )
    end

    it "returns 400 event.invalid_payload" do
      post "/v1/events", params: body, headers: headers
      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)["error"]["code"]).to eq("event.invalid_payload")
    end
  end

  # ─── Auth & signature failures ────────────────────────────────────────────

  context "missing Authorization" do
    it "returns 401" do
      post "/v1/events", params: body,
           headers: headers.except("Authorization")
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "wrong API key" do
    it "returns 401" do
      post "/v1/events", params: body,
           headers: headers.merge("Authorization" => "Bearer mk_wrong")
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "missing Idempotency-Key" do
    it "returns 400 event.idempotency_key_required" do
      post "/v1/events", params: body,
           headers: headers.except("Idempotency-Key")
      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)["error"]["code"]).to eq("event.idempotency_key_required")
    end
  end

  context "invalid HMAC signature" do
    it "returns 401 auth.invalid_signature" do
      post "/v1/events", params: body,
           headers: headers.merge("X-Signature" => "deadbeef")
      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)["error"]["code"]).to eq("auth.invalid_signature")
    end
  end

  context "valid signature but swapped Idempotency-Key" do
    # HMAC payload deviation (TRADEOFFS 1.3b): signing over "key:body" means
    # replaying with a different key — even with a valid body hash — is rejected.
    it "returns 401 because swapped key breaks the HMAC" do
      other_key = SecureRandom.uuid
      # Signature was computed over original idem_key, not other_key
      swapped_headers = headers.merge("Idempotency-Key" => other_key)
      post "/v1/events", params: body, headers: swapped_headers
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
