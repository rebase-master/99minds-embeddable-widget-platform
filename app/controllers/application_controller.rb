class ApplicationController < ActionController::API
  MAX_BODY_BYTES = 64 * 1024

  before_action :enforce_body_size_limit

  rescue_from JSON::ParserError do
    render_api_error(status: :bad_request, code: "request.invalid_json",
                     message: "Body is not valid JSON.")
  end

  rescue_from ActsAsTenant::Errors::NoTenantSet do
    render_api_error(status: :unauthorized, code: "auth.unauthorized",
                     message: "Tenant context required for this endpoint.")
  end

  rescue_from ActiveRecord::RecordNotFound do
    render_api_error(status: :not_found, code: "record.not_found",
                     message: "Record not found.")
  end

  rescue_from ApiError do |e|
    render_api_error(status: e.status, code: e.code, message: e.message)
  end

  private

  def render_api_error(status:, code:, message:)
    render json: { error: { code: code, message: message } }, status: status
  end

  def enforce_body_size_limit
    return unless request.post? || request.patch? || request.put?
    return if request.content_length.to_i <= MAX_BODY_BYTES
    render_api_error(status: :payload_too_large, code: "request.body_too_large",
                     message: "Request body exceeds maximum #{MAX_BODY_BYTES} bytes.")
  end
end
