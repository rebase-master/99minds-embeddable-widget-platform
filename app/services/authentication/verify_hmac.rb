module Authentication
  class VerifyHmac
    # Signs Idempotency-Key + ":" + body to close the in-window replay hole.
    # See TRADEOFFS.md Stage 1.3b.
    def self.call(merchant:, signature:, idempotency_key:, body:)
      return false if signature.blank? || idempotency_key.blank? || merchant.nil?

      normalized = signature.to_s.strip.downcase
      expected = OpenSSL::HMAC.hexdigest("SHA256", merchant.hmac_secret, "#{idempotency_key}:#{body}")
      return false if expected.bytesize != normalized.bytesize

      ActiveSupport::SecurityUtils.secure_compare(expected, normalized)
    end
  end
end
