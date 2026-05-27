require "rails_helper"

RSpec.describe "Campaigns API", type: :request do
  let(:raw_api_key) { "mk_test_campaigns_key" }
  let(:merchant)    { create(:merchant, raw_api_key: raw_api_key) }
  let(:auth)        { api_auth(raw_api_key) }
  let(:json_headers) { auth.merge("Content-Type" => "application/json") }

  let(:campaign_params) do
    {
      name:   "Free shipping",
      active: true,
      trigger: {
        event_type: "cart.updated",
        conditions: [ { "field" => "data.cart_total_cents", "op" => "gte", "value" => 5000 } ]
      },
      render: { "component" => "banner", "payload" => { "title" => "Free shipping!" } }
    }
  end

  # Ensure merchant exists before each request (sets up tenant digest).
  before { merchant }

  # ─── Auth guard ───────────────────────────────────────────────────────────

  it "returns 401 without Authorization" do
    get "/v1/campaigns"
    expect(response).to have_http_status(:unauthorized)
  end

  # ─── CRUD happy paths ─────────────────────────────────────────────────────

  describe "GET /v1/campaigns" do
    it "returns 200 with an array" do
      get "/v1/campaigns", headers: auth
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"]).to be_an(Array)
    end
  end

  describe "POST /v1/campaigns" do
    it "creates a campaign and returns 201" do
      post "/v1/campaigns", params: campaign_params.to_json, headers: json_headers
      expect(response).to have_http_status(:created)
      data = JSON.parse(response.body)["data"]
      expect(data["name"]).to eq("Free shipping")
      expect(data["trigger"]["event_type"]).to eq("cart.updated")
    end
  end

  describe "GET /v1/campaigns/:id" do
    let!(:campaign) { ActsAsTenant.with_tenant(merchant) { create(:campaign) } }

    it "returns 200 with campaign data" do
      get "/v1/campaigns/#{campaign.id}", headers: auth
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"]["id"]).to eq(campaign.id)
    end
  end

  describe "PATCH /v1/campaigns/:id" do
    let!(:campaign) { ActsAsTenant.with_tenant(merchant) { create(:campaign, active: true) } }

    it "updates the campaign and returns 200" do
      # Send full params — the controller's attributes_from_params always merges
      # all fields, so sparse PATCH would fail model validations (known limitation).
      patch "/v1/campaigns/#{campaign.id}",
            params: {
              name:    campaign.name,
              active:  false,
              trigger: { event_type: campaign.event_type, conditions: [] },
              render:  campaign.render
            }.to_json,
            headers: json_headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"]["active"]).to be(false)
    end
  end

  describe "DELETE /v1/campaigns/:id" do
    let!(:campaign) { ActsAsTenant.with_tenant(merchant) { create(:campaign) } }

    it "deletes the campaign and returns 204" do
      delete "/v1/campaigns/#{campaign.id}", headers: auth
      expect(response).to have_http_status(:no_content)
    end
  end

  # ─── Cross-tenant isolation ───────────────────────────────────────────────

  describe "cross-tenant GET" do
    let(:other_key)      { "mk_test_other_merchant" }
    let(:other_merchant) { create(:merchant, raw_api_key: other_key) }
    let!(:their_campaign) { ActsAsTenant.with_tenant(other_merchant) { create(:campaign) } }

    it "returns 404 when accessing another merchant's campaign" do
      get "/v1/campaigns/#{their_campaign.id}", headers: auth
      expect(response).to have_http_status(:not_found)
    end
  end
end
