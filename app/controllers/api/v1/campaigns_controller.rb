module Api
  module V1
    class CampaignsController < ApplicationController
      include AuthenticateMerchant

      def index
        campaigns = Campaign.order(created_at: :desc).limit(100)
        render json: { data: campaigns.map { |c| serialize(c) } }
      end

      def show
        render json: { data: serialize(Campaign.find(params[:id])) }
      end

      def create
        campaign = Campaign.new(attributes_from_params)
        if campaign.save
          render json: { data: serialize(campaign) }, status: :created
        else
          render_validation_error(campaign)
        end
      end

      def update
        campaign = Campaign.find(params[:id])
        if campaign.update(attributes_from_params)
          render json: { data: serialize(campaign) }
        else
          render_validation_error(campaign)
        end
      end

      def destroy
        Campaign.find(params[:id]).destroy!
        head :no_content
      end

      private

      def attributes_from_params
        trigger = ensure_hash(params[:trigger], "trigger")
        render_data = ensure_hash(params[:render], "render")
        active = params[:active].nil? ? true : params[:active]

        {
          name: params[:name],
          active: active,
          event_type: trigger["event_type"],
          conditions: trigger["conditions"] || [],
          render: render_data
        }
      end

      def ensure_hash(value, field_name)
        return {} if value.nil?
        return value.to_unsafe_h if value.is_a?(ActionController::Parameters)
        return value if value.is_a?(Hash)
        raise ApiError.new(status: :unprocessable_entity, code: "campaign.invalid",
                           message: "#{field_name} must be a JSON object.")
      end

      def serialize(c)
        {
          id: c.id,
          name: c.name,
          active: c.active,
          trigger: { event_type: c.event_type, conditions: c.conditions },
          render: c.render
        }
      end

      def render_validation_error(record)
        render_api_error(status: :unprocessable_entity, code: "campaign.invalid",
                         message: record.errors.full_messages.join("; "))
      end
    end
  end
end
