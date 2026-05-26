module AuthenticateMerchant
  extend ActiveSupport::Concern

  included do
    set_current_tenant_through_filter
    before_action :authenticate_merchant!
  end

  private

  def authenticate_merchant!
    key = request.headers["Authorization"].to_s.sub(/\ABearer /, "")
    return render_unauthorized if key.empty?

    digest = Digest::SHA256.hexdigest(key + ENV.fetch("API_KEY_PEPPER"))
    merchant = Merchant.find_by(api_key_digest: digest)
    return render_unauthorized unless merchant

    set_current_tenant(merchant)
  end

  def render_unauthorized
    render_api_error(status: :unauthorized, code: "auth.unauthorized",
                     message: "Invalid or missing API key.")
  end
end
