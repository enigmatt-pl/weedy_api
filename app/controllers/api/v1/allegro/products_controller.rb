module Api
  module V1
    module Allegro
      class ProductsController < ApplicationController
        before_action :authenticate_user!
        before_action :ensure_allegro_connected

        def index
          service = ::Allegro::ProductSearchService.new(current_user, params[:query])
          result = service.call

          if result[:error]
            render json: result, status: :bad_request
          else
            render json: result
          end
        end

        private

        def ensure_allegro_connected
          return if current_user.allegro_integration&.access_token.present?

          render json: { error: 'Allegro account not connected' }, status: :unauthorized
        end
      end
    end
  end
end
