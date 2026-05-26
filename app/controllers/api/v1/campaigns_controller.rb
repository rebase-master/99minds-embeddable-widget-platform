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
        trigger = params[:trigger] || {}
        {
          name: params[:name],
          active: params.fetch(:active, true),
          event_type: trigger[:event_type],
          conditions: trigger[:conditions] || [],
          render: params[:render] || {}
        }
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
