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

# Ready-to-paste curls with pre-computed signatures for each test scenario.
# Body must be byte-identical to what curl sends — JSON.generate emits a stable single-line form.
sign = ->(idem, body) { OpenSSL::HMAC.hexdigest("SHA256", hmac_secret, "#{idem}:#{body}") }

# Test 1 (happy path) + Test 2 (content mismatch) share the same Idempotency-Key.
idem_ab     = SecureRandom.uuid
occurred_at = Time.current.utc.iso8601
body_a      = JSON.generate(
  "shopper_id" => shopper_id, "event_type" => "cart.updated", "occurred_at" => occurred_at,
  "data" => { "cart_total_cents" => 7500, "currency" => "USD", "item_count" => 5 }
)
body_b = JSON.generate(
  "shopper_id" => shopper_id, "event_type" => "cart.updated", "occurred_at" => occurred_at,
  "data" => { "cart_total_cents" => 8500, "currency" => "USD", "item_count" => 5 }
)
sig_a = sign.call(idem_ab, body_a)
sig_b = sign.call(idem_ab, body_b)

# Test 3 (outside replay window): fresh Idempotency-Key, occurred_at 10 minutes ago.
idem_c   = SecureRandom.uuid
stale_at = (Time.current - 10.minutes).utc.iso8601
body_c   = JSON.generate(
  "shopper_id" => shopper_id, "event_type" => "cart.updated", "occurred_at" => stale_at,
  "data" => { "cart_total_cents" => 7500, "currency" => "USD", "item_count" => 5 }
)
sig_c = sign.call(idem_c, body_c)

# Test 4 (invalid payload): data is a string, not an object.
idem_d = SecureRandom.uuid
body_d = JSON.generate(
  "shopper_id" => shopper_id, "event_type" => "cart.updated", "occurred_at" => occurred_at,
  "data" => "not a hash"
)
sig_d = sign.call(idem_d, body_d)

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

  ─── Step 1: open the demo page ────────────────────────────────

     http://localhost:3000/sdk_demo.html?token=#{token}

  Wait for "Connected. Waiting for triggers."

  ─── Step 2: smoke-test scenarios (paste in order) ─────────────

  ╭── Test 1: happy path → 202, demo page prints 2 triggers ─────╮

  curl -X POST http://localhost:3000/v1/events \\
    -H "Authorization: Bearer #{api_key}" \\
    -H "Idempotency-Key: #{idem_ab}" \\
    -H "X-Signature: #{sig_a}" \\
    -H "Content-Type: application/json" \\
    -d '#{body_a}'

  ╭── Test 2: content mismatch → 422 (RUN AFTER TEST 1) ─────────╮
  ╭── Same Idempotency-Key, different cart_total_cents, signature recomputed.

  curl -X POST http://localhost:3000/v1/events \\
    -H "Authorization: Bearer #{api_key}" \\
    -H "Idempotency-Key: #{idem_ab}" \\
    -H "X-Signature: #{sig_b}" \\
    -H "Content-Type: application/json" \\
    -d '#{body_b}'

  ╭── Test 3: outside replay window → 400 ───────────────────────╮
  ╭── occurred_at is 10 min ago; fresh Idempotency-Key.

  curl -X POST http://localhost:3000/v1/events \\
    -H "Authorization: Bearer #{api_key}" \\
    -H "Idempotency-Key: #{idem_c}" \\
    -H "X-Signature: #{sig_c}" \\
    -H "Content-Type: application/json" \\
    -d '#{body_c}'

  ╭── Test 4: invalid payload (data is a string) → 400 ──────────╮

  curl -X POST http://localhost:3000/v1/events \\
    -H "Authorization: Bearer #{api_key}" \\
    -H "Idempotency-Key: #{idem_d}" \\
    -H "X-Signature: #{sig_d}" \\
    -H "Content-Type: application/json" \\
    -d '#{body_d}'

  Only Test 1 should make the demo page light up. Tests 2–4 should
  return error envelopes and the page stays quiet.

  All four curls are valid for ~5 minutes from this seed time
  (replay-window cutoff). Re-seed if you take longer.

OUTPUT
