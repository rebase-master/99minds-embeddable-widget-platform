module Api
  module V1
    class ThemesController < ApplicationController
      include AuthenticateMerchant

      def update
        theme = params[:theme]
        unless theme.is_a?(ActionController::Parameters) || theme.is_a?(Hash)
          return render_api_error(status: :bad_request, code: "theme.invalid",
                                  message: "theme must be a JSON object.")
        end

        merchant = ActsAsTenant.current_tenant
        new_theme = theme.is_a?(ActionController::Parameters) ? theme.to_unsafe_h : theme
        # Bumping theme_version busts the per-merchant cache key in Sdk::ThemesController.
        merchant.update!(theme: new_theme, theme_version: merchant.theme_version + 1)

        render json: { data: { theme: merchant.theme, theme_version: merchant.theme_version } }
      end
    end
  end
end
