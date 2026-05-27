FactoryBot.define do
  factory :merchant do
    # raw_api_key is transient — pass it in to control the known-good key for auth tests.
    transient do
      raw_api_key { "mk_test_#{SecureRandom.hex(8)}" }
    end

    sequence(:name) { |n| "Merchant #{n}" }
    api_key_digest { Digest::SHA256.hexdigest(raw_api_key + ENV.fetch("API_KEY_PEPPER")) }
    hmac_secret    { SecureRandom.hex(32) }
    sequence(:sdk_public_key) { |n| "sdk_test_#{n}_#{SecureRandom.hex(4)}" }
    theme          { { "colors" => { "primary" => "#5B21B6" } } }
  end
end
