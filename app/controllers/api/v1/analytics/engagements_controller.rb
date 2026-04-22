module Api
  module V1
    module Analytics
      class EngagementsController < ActionController::API
        include ActionController::HttpAuthentication::Basic::ControllerMethods

        before_action :authenticate_analytics!

        def create
          begin
            raw_payload = params[:pd].to_s.reverse
            decoded = Base64.decode64(raw_payload)
            parsed_data = JSON.parse(decoded)
          rescue => e
            Rails.logger.warn "Failed to parse fuzzed engagement payload: #{e.message}"
            return head :bad_request
          end

          permitted_params = ActionController::Parameters.new(parsed_data).permit(
            :visitor_id, :path, :scroll_depth_pct, 
            :scroll_milestones, :time_on_page_sec, 
            :click_count, :exit_intent
          )

          # Find the latest page view for this visitor and path
          view = PageView.where(
            visitor_id: permitted_params[:visitor_id], 
            path: permitted_params[:path]
          ).order(created_at: :desc).first
                       
          if view
            view.update(permitted_params.except(:visitor_id, :path))
            head :ok
          else
            head :not_found
          end
        rescue => e
          Rails.logger.error "Engagement Error: #{e.message}"
          head :ok # Don't break if saving fails
        end

        private

        def authenticate_analytics!
          # Handle both standard Basic Auth and the ?_auth URL param for sendBeacon
          auth_token = params[:_auth]
          
          if auth_token.present?
            begin
              # Decode Base64 if needed, or check if it matches the expected credentials
              # Here we assume _auth is the base64 encoded "ID:SECRET"
              decoded_auth = Base64.decode64(auth_token) rescue ""
              username, password = decoded_auth.split(':', 2)
              
              unless username == ENV['ANALYTICS_USER_ID'] && password == ENV['ANALYTICS_SECRET_KEY']
                head :unauthorized
              end
            rescue
              head :unauthorized
            end
          else
            # Fallback to standard HTTP Basic Auth
            authenticate_or_request_with_http_basic do |username, password|
              username == ENV['ANALYTICS_USER_ID'] && password == ENV['ANALYTICS_SECRET_KEY']
            end
          end
        end
      end
    end
  end
end
