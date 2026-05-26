class ApplicationController < ActionController::API
  rescue_from JSON::ParserError do
    render_api_error(status: :bad_request, code: "event.invalid_json",
                     message: "Body is not valid JSON.")
  end

  rescue_from Events::Ingest::Error do |e|
    render_api_error(status: e.status, code: e.code, message: e.message)
  end

  private

  def render_api_error(status:, code:, message:)
    render json: { error: { code: code, message: message } }, status: status
  end
end
