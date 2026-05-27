require "rails_helper"

RSpec.describe "GET /v1/sdk/theme", type: :request do
  let(:merchant) { create(:merchant) }
  let(:sdk_key)  { merchant.sdk_public_key }

  # ─── Happy path ───────────────────────────────────────────────────────────

  it "returns 200 with the merchant theme" do
    get "/v1/sdk/theme", headers: { "Authorization" => "Bearer #{sdk_key}" }
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["data"]).to include("colors")
  end

  # ─── ETag caching ─────────────────────────────────────────────────────────

  it "returns 304 on a matching ETag" do
    get "/v1/sdk/theme", headers: { "Authorization" => "Bearer #{sdk_key}" }
    etag = response.headers["ETag"]
    expect(etag).to be_present

    get "/v1/sdk/theme", headers: {
      "Authorization"  => "Bearer #{sdk_key}",
      "If-None-Match"  => etag
    }
    expect(response).to have_http_status(:not_modified)
  end

  # ─── Auth failure ─────────────────────────────────────────────────────────

  it "returns 401 with an invalid SDK key" do
    get "/v1/sdk/theme", headers: { "Authorization" => "Bearer sdk_wrong" }
    expect(response).to have_http_status(:unauthorized)
    expect(JSON.parse(response.body)["error"]["code"]).to eq("auth.unauthorized")
  end

  it "returns 401 with no Authorization" do
    get "/v1/sdk/theme"
    expect(response).to have_http_status(:unauthorized)
  end
end
