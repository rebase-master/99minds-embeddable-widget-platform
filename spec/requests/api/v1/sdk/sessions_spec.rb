require "rails_helper"

RSpec.describe "POST /v1/sdk/sessions", type: :request do
  let(:raw_api_key) { "mk_test_sessions_key" }
  let(:merchant)    { create(:merchant, raw_api_key: raw_api_key) }
  let(:auth)        { api_auth(raw_api_key) }
  let(:json_headers) { auth.merge("Content-Type" => "application/json") }

  before { merchant }

  # ─── Happy path ───────────────────────────────────────────────────────────

  it "returns 201 with a token and expires_in" do
    post "/v1/sdk/sessions",
         params: { shopper_id: "shp_alice" }.to_json,
         headers: json_headers
    expect(response).to have_http_status(:created)
    data = JSON.parse(response.body)["data"]
    expect(data["token"]).to be_present
    expect(data["expires_in"]).to eq(Sdk::SessionToken::TTL.to_i)
  end

  it "mints a token that decodes to the correct claims" do
    post "/v1/sdk/sessions",
         params: { shopper_id: "shp_alice" }.to_json,
         headers: json_headers
    token = JSON.parse(response.body)["data"]["token"]
    claims = Sdk::SessionToken.decode(token)
    expect(claims).to be_a(Hash)
    expect(claims[:merchant_id].to_i).to eq(merchant.id)
    expect(claims[:shopper_id]).to eq("shp_alice")
  end

  # ─── Input validation ─────────────────────────────────────────────────────

  it "returns 400 when shopper_id is missing" do
    post "/v1/sdk/sessions", params: {}.to_json, headers: json_headers
    expect(response).to have_http_status(:bad_request)
    expect(JSON.parse(response.body)["error"]["code"]).to eq("session.shopper_id_required")
  end

  it "returns 400 when shopper_id is an empty string" do
    post "/v1/sdk/sessions",
         params: { shopper_id: "" }.to_json,
         headers: json_headers
    expect(response).to have_http_status(:bad_request)
    expect(JSON.parse(response.body)["error"]["code"]).to eq("session.shopper_id_required")
  end

  # ─── Auth failure ─────────────────────────────────────────────────────────

  it "returns 401 without Authorization" do
    post "/v1/sdk/sessions",
         params: { shopper_id: "shp_alice" }.to_json,
         headers: { "Content-Type" => "application/json" }
    expect(response).to have_http_status(:unauthorized)
  end

  it "returns 401 with a wrong API key" do
    post "/v1/sdk/sessions",
         params: { shopper_id: "shp_alice" }.to_json,
         headers: api_auth("mk_wrong").merge("Content-Type" => "application/json")
    expect(response).to have_http_status(:unauthorized)
  end
end
