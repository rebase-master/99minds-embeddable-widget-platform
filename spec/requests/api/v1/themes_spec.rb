require "rails_helper"

RSpec.describe "PATCH /v1/theme", type: :request do
  let(:raw_api_key) { "mk_test_theme_key" }
  let(:merchant)    { create(:merchant, raw_api_key: raw_api_key) }
  let(:json_headers) { api_auth(raw_api_key).merge("Content-Type" => "application/json") }

  before { merchant }

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

  it "returns 400 when theme is not a JSON object" do
    patch "/v1/theme",
          params: { theme: "not a hash" }.to_json,
          headers: json_headers
    expect(response).to have_http_status(:bad_request)
    expect(JSON.parse(response.body)["error"]["code"]).to eq("theme.invalid")
  end

  it "returns 401 without Authorization" do
    patch "/v1/theme",
          params: { theme: { "x" => 1 } }.to_json,
          headers: { "Content-Type" => "application/json" }
    expect(response).to have_http_status(:unauthorized)
  end
end
