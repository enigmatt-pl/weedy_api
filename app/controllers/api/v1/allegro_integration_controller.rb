module Api
  module V1
    class AllegroIntegrationController < ApplicationController
      before_action :authenticate_user!

      def auth_url
        service = ::Allegro::AuthService.new(current_user)
        render json: { url: service.auth_url }
      end

      def callback
        service = ::Allegro::AuthService.new(current_user)
        result = service.exchange_code(params[:code])

        if result[:success]
          render json: { message: 'Connected successfully' }, status: :ok
        else
          render json: { error: 'Failed to connect', detail: result[:error] }, status: :unprocessable_content
        end
      end

      def status
        connected = current_user.allegro_integration.present?
        render json: { connected: connected }
      end
    end
  end
end
