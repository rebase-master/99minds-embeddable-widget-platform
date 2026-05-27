# Idempotent: skip if anything's already seeded.
if Merchant.exists?
  puts "Merchants already exist; skipping seed. Run `bin/rails db:reset` to start over."
  return
end

require "securerandom"
require "openssl"
require "json"

api_key        = "mk_dev_#{SecureRandom.hex(16)}"
hmac_secret    = SecureRandom.hex(32)
sdk_public_key = "sdk_dev_#{SecureRandom.hex(16)}"

merchant = Merchant.create!(
  name:            "Demo Merchant",
  api_key_digest:  Digest::SHA256.hexdigest(api_key + ENV.fetch("API_KEY_PEPPER")),
  hmac_secret:     hmac_secret,
  sdk_public_key:  sdk_public_key,
  theme: {
    "colors" => { "primary" => "#5B21B6", "background" => "#FFFFFF", "text" => "#1F2937" },
    "font"   => "Inter, system-ui, sans-serif",
    "labels" => { "checkout_cta" => "Continue to checkout" }
  }
)

ActsAsTenant.with_tenant(merchant) do
  Campaign.create!(
    name:       "Free shipping over $50",
    active:     true,
    event_type: "cart.updated",
    conditions: [ { "field" => "data.cart_total_cents", "op" => "gte", "value" => 5000 } ],
    render: {
      "component" => "banner",
      "payload"   => {
        "title" => "You've unlocked free shipping",
        "body"  => "No code needed — applied at checkout",
        "cta"   => { "label" => "Continue", "url" => "/checkout" }
      }
    }
  )

  Campaign.create!(
    name:       "Big-cart welcome modal",
    active:     true,
    event_type: "cart.updated",
    conditions: [ { "field" => "data.item_count", "op" => "gte", "value" => 5 } ],
    render: {
      "component" => "modal",
      "payload"   => { "title" => "Nice haul!", "body" => "You have 5+ items in your cart." }
    }
  )
end

shopper_id = "shp_demo"
token = Sdk::SessionToken.encode(merchant_id: merchant.id, shopper_id: shopper_id)

# Ready-to-paste curl with pre-computed signature.
# Body must be byte-identical to what curl sends — JSON.generate emits a stable single-line form.
idem_key    = SecureRandom.uuid
occurred_at = Time.current.utc.iso8601
body        = JSON.generate(
  "shopper_id"  => shopper_id,
  "event_type"  => "cart.updated",
  "occurred_at" => occurred_at,
  "data"        => { "cart_total_cents" => 7500, "currency" => "USD", "item_count" => 5 }
)
signature = OpenSSL::HMAC.hexdigest("SHA256", hmac_secret, "#{idem_key}:#{body}")

puts <<~OUTPUT

  ═══════════════════════════════════════════════════════════════
   Seeded demo merchant (DEV credentials — rotate before prod)
  ═══════════════════════════════════════════════════════════════

   Merchant ID:    #{merchant.id}
   Name:           #{merchant.name}

   API key:        #{api_key}
   HMAC secret:    #{hmac_secret}
   SDK public key: #{sdk_public_key}

   Demo shopper:   #{shopper_id}
   Session token:  #{token}
   (15-minute TTL. Mint a fresh one via POST /v1/sdk/sessions.)

  ─── Smoke test ────────────────────────────────────────────────

  1. Open the demo page (paste in browser):

       http://localhost:3000/sdk_demo.html?token=#{token}

     Wait for "Connected. Waiting for triggers."

  2. Fire a matching event (pre-computed signature, valid 5 min):

       curl -X POST http://localhost:3000/v1/events \\
         -H "Authorization: Bearer #{api_key}" \\
         -H "Idempotency-Key: #{idem_key}" \\
         -H "X-Signature: #{signature}" \\
         -H "Content-Type: application/json" \\
         -d '#{body}'

  3. Demo page should print both campaigns' render payloads within ~1s.

OUTPUT
