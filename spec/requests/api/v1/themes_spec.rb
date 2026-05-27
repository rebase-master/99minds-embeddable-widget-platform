require "rails_helper"

RSpec.describe "PATCH /v1/theme", type: :request do
  let(:raw_api_key) { "mk_test_theme_key" }
  let(:merchant)    { create(:merchant, raw_api_key: raw_api_key) }
  let(:json_headers) { api_auth(raw_api_key).merge("Content-Type" => "application/json") }

  before { merchant }

  # ─── Happy path ───────────────────────────────────────────────────────────

  it "updates the theme and bumps theme_version" do
    initial_version = merchant.theme_version
    patch "/v1/theme",
          params: { theme: { "colors" => { "primary" => "#000000" } } }.to_json,
          headers: json_headers
    expect(response).to have_http_status(:ok)
    data = JSON.parse(response.body)["data"]
    expect(data["theme"]).to eq({ "colors" => { "primary" => "#000000" } })
    expect(data["theme_version"]).to eq(initial_version + 1)
  end

  it "persists the change across requests" do
    patch "/v1/theme",
          params: { theme: { "font" => "Inter" } }.to_json,
          headers: json_headers
    expect(merchant.reload.theme).to eq({ "font" => "Inter" })
  end

  it "increments theme_version on each successful update" do
    3.times do |i|
      patch "/v1/theme",
            params: { theme: { "v" => i } }.to_json,
            headers: json_headers
    end
    expect(merchant.reload.theme_version).to eq(3)
  end

  # ─── Input validation ─────────────────────────────────────────────────────

  it "returns 400 when theme is a string" do
    patch "/v1/theme",
          params: { theme: "not a hash" }.to_json,
          headers: json_headers
    expect(response).to have_http_status(:bad_request)
    expect(JSON.parse(response.body)["error"]["code"]).to eq("theme.invalid")
  end

  it "returns 400 when theme key is missing" do
    patch "/v1/theme", params: {}.to_json, headers: json_headers
    expect(response).to have_http_status(:bad_request)
    expect(JSON.parse(response.body)["error"]["code"]).to eq("theme.invalid")
  end

  it "returns 400 when theme is null" do
    patch "/v1/theme",
          params: { theme: nil }.to_json,
          headers: json_headers
    expect(response).to have_http_status(:bad_request)
    expect(JSON.parse(response.body)["error"]["code"]).to eq("theme.invalid")
  end

  # ─── Auth failures ────────────────────────────────────────────────────────

  it "returns 401 without Authorization" do
    patch "/v1/theme",
          params: { theme: { "x" => 1 } }.to_json,
          headers: { "Content-Type" => "application/json" }
    expect(response).to have_http_status(:unauthorized)
  end

  it "returns 401 with a wrong API key" do
    patch "/v1/theme",
          params: { theme: { "x" => 1 } }.to_json,
          headers: api_auth("mk_wrong").merge("Content-Type" => "application/json")
    expect(response).to have_http_status(:unauthorized)
  end

  # ─── Cross-tenant isolation ───────────────────────────────────────────────

  describe "cross-tenant isolation" do
    let(:other_key)      { "mk_test_other_theme" }
    let!(:other_merchant) do
      create(:merchant, raw_api_key: other_key, theme: { "colors" => { "primary" => "#FF0000" } })
    end

    it "does not affect another merchant's theme" do
      patch "/v1/theme",
            params: { theme: { "colors" => { "primary" => "#0000FF" } } }.to_json,
            headers: json_headers
      expect(other_merchant.reload.theme).to eq({ "colors" => { "primary" => "#FF0000" } })
      expect(other_merchant.theme_version).to eq(0)
    end
  end

  # ─── Cache integration: SDK read reflects the update ──────────────────────

  it "the SDK theme endpoint returns the new theme after update" do
    patch "/v1/theme",
          params: { theme: { "label" => "fresh" } }.to_json,
          headers: json_headers

    get "/v1/sdk/theme", headers: { "Authorization" => "Bearer #{merchant.sdk_public_key}" }
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["data"]).to eq({ "label" => "fresh" })
  end
end
