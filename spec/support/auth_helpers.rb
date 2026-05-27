module AuthHelpers
  # Bearer auth header for merchant API key.
  def api_auth(raw_api_key)
    { "Authorization" => "Bearer #{raw_api_key}" }
  end

  # HMAC-SHA256 over "#{idempotency_key}:#{body}" — matches VerifyHmac.call.
  def hmac_sig(merchant, idempotency_key, body)
    OpenSSL::HMAC.hexdigest("SHA256", merchant.hmac_secret, "#{idempotency_key}:#{body}")
  end

  # Full headers for a signed event POST.
  def event_headers(raw_api_key, merchant, idempotency_key, body)
    api_auth(raw_api_key).merge(
      "Idempotency-Key" => idempotency_key,
      "X-Signature" => hmac_sig(merchant, idempotency_key, body),
      "Content-Type" => "application/json"
    )
  end
end
