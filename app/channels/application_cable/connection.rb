module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :merchant_id, :shopper_id

    def connect
      claims = ::Sdk::SessionToken.decode(request.params[:token])
      reject_unauthorized_connection unless claims.is_a?(Hash)

      # MessageVerifier serializer may yield symbol or string keys depending on
      # Rails config; accept either (CLAUDE.md Runtime Gotcha §2).
      self.merchant_id = claims[:merchant_id] || claims["merchant_id"]
      self.shopper_id = claims[:shopper_id] || claims["shopper_id"]
      reject_unauthorized_connection if merchant_id.blank? || shopper_id.blank?
    end
  end
end
