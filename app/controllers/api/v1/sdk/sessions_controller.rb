module Api
  module V1
    module Sdk
      class SessionsController < ApplicationController
        include AuthenticateMerchant

        def create
          shopper_id = params[:shopper_id]
          unless shopper_id.is_a?(String) && !shopper_id.empty?
            return render_api_error(status: :bad_request, code: "session.shopper_id_required",
                                    message: "shopper_id is required (non-empty string).")
          end

          token = ::Sdk::SessionToken.encode(
            merchant_id: ActsAsTenant.current_tenant.id,
            shopper_id: shopper_id
          )
          render json: { data: { token: token, expires_in: ::Sdk::SessionToken::TTL.to_i } },
                 status: :created
        end
      end
    end
  end
end
