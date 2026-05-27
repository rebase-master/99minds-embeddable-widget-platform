module Sdk
  module SessionToken
    PURPOSE = :sdk_session
    TTL = 15.minutes

    def self.encode(merchant_id:, shopper_id:)
      verifier.generate({ merchant_id: merchant_id, shopper_id: shopper_id },
                        purpose: PURPOSE, expires_in: TTL)
    end

    # Returns the claims hash on success, nil on any verification failure
    # (tampered, expired, wrong purpose). One rescue path for callers.
    def self.decode(token)
      verifier.verify(token, purpose: PURPOSE)
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end

    def self.verifier
      @verifier ||= ActiveSupport::MessageVerifier.new(ENV.fetch("SDK_JWT_SIGNING_KEY"))
    end
    private_class_method :verifier
  end
end
