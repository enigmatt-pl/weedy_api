module Api
  module V1
    class AllegroAuthController < ApplicationController
      before_action :authenticate_user!, only: [:auth]

      # GET /api/v1/allegro/auth
      # Initiates the Allegro OAuth flow by redirecting to Allegro's authorize page.
      def auth
        # In a real app, we might want to store a 'state' in session/DB to prevent CSRF.
        # For simplicity, we'll use a unique identifier or just the user ID if appropriate.
        state = SecureRandom.hex(16)

        # Save state to user temporarily
        current_user.update!(allegro_auth_state: state)

        query = {
          response_type: 'code',
          client_id: allegro_client_id(current_user),
          redirect_uri: allegro_redirect_uri,
          state: state,
          prompt: 'confirm',
          scope: 'allegro:api:profile allegro:api:orders:read allegro:api:offers:read allegro:api:offers:write'
        }.to_query

        authorize_url = "#{allegro_base_url}/auth/oauth/authorize?#{query}"

        render json: { url: authorize_url }, status: :ok
      rescue StandardError => e
        Rails.logger.error "[AllegroAuth] ❌ Error generating Auth URL: #{e.message}"
        render json: { error: e.message }, status: :internal_server_error
      end

      # GET /api/v1/allegro/callback
      # Receives the authorization code from Allegro and exchanges it for tokens.
      def callback
        code = params[:code]
        state = params[:state]

        if code.blank? || state.blank?
          return redirect_to "#{frontend_url}/settings?error=allegro_auth_failed", allow_other_host: true
        end

        user = User.find_by(allegro_auth_state: state)

        return redirect_to "#{frontend_url}/settings?error=user_not_found", allow_other_host: true if user.nil?

        # EXCHANGE CODE FOR TOKEN
        response = exchange_code_for_token(code, user)

        if response[:success]
          data = response[:data]
          expires_at = Time.current + data['expires_in'].to_i.seconds

          integration = user.allegro_integration || user.build_allegro_integration
          integration.update!(
            access_token: data['access_token'],
            refresh_token: data['refresh_token'],
            expires_at: expires_at,
            client_id: allegro_client_id(user),
            client_secret: allegro_client_secret(user)
          )
          user.update!(allegro_auth_state: nil)
          redirect_to "#{frontend_url}/dashboard?allegro=connected", allow_other_host: true
        else
          redirect_to "#{frontend_url}/settings?error=token_exchange_failed", allow_other_host: true
        end
      end

      private

      def allegro_client_id(user)
        user.allegro_integration&.client_id.presence || ENV.fetch('ALLEGRO_CLIENT_ID')
      end

      def allegro_client_secret(user)
        user.allegro_integration&.client_secret.presence || ENV.fetch('ALLEGRO_CLIENT_SECRET')
      end

      def allegro_redirect_uri
        ENV.fetch('ALLEGRO_REDIRECT_URI')
      end

      def allegro_base_url
        ENV.fetch('ALLEGRO_ENV', 'sandbox') == 'sandbox' ? 'https://allegro.pl.allegrosandbox.pl' : 'https://allegro.pl'
      end

      def frontend_url
        ENV.fetch('FRONTEND_URL', 'http://localhost:5173')
      end

      def exchange_code_for_token(code, user)
        uri = URI("#{allegro_base_url}/auth/oauth/token")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri.path)
        request.basic_auth(allegro_client_id(user), allegro_client_secret(user))
        request.set_form_data({
                                grant_type: 'authorization_code',
                                code: code,
                                redirect_uri: allegro_redirect_uri
                              })

        Rails.logger.info "[AllegroAuth] 🔑 Exchanging code for token... Redirect URI: #{allegro_redirect_uri}"
        response = http.request(request)

        if response.is_a?(Net::HTTPSuccess)
          Rails.logger.info "[AllegroAuth] ✅ Token exchange successful!"
          data = JSON.parse(response.body)
          { success: true, data: data }
        else
          Rails.logger.error "[AllegroAuth] ❌ Token exchange FAILED! Status: #{response.code}, Body: #{response.body}"
          { success: false, error: response.body }
        end
      end
    end
  end
end
