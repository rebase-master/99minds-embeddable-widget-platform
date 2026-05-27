module Api
  module V1
    module Sdk
      class ThemesController < ApplicationController
        set_current_tenant_through_filter
        before_action :authenticate_sdk!

        def show
          merchant = ActsAsTenant.current_tenant
          return unless stale?(etag: merchant.theme_version, public: false)

          theme = Rails.cache.fetch("theme:#{merchant.id}:v#{merchant.theme_version}",
                                    expires_in: 24.hours) do
            merchant.theme
          end
          render json: { data: theme }
        end

        private

        def authenticate_sdk!
          key = request.headers["Authorization"].to_s.sub(/\ABearer /i, "")
          merchant = Merchant.find_by(sdk_public_key: key) if key.present?
          return set_current_tenant(merchant) if merchant

          render_api_error(status: :unauthorized, code: "auth.unauthorized",
                           message: "Invalid or missing SDK public key.")
        end
      end
    end
  end
end
