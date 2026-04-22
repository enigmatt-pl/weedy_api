module Allegro
  class TokenRefreshService
    def base_url
      ENV.fetch('ALLEGRO_ENV', 'sandbox') == 'sandbox' ? 'https://allegro.pl.allegrosandbox.pl' : 'https://allegro.pl'
    end

    def token_endpoint
      "#{base_url}/auth/oauth/token"
    end

    def initialize(integration)
      @integration = integration
    end

    def refresh
      return @integration.access_token unless @integration.expired?

      conn = Faraday.new do |f|
        f.request :url_encoded
        f.adapter Faraday.default_adapter
      end

      response = conn.post(token_endpoint) do |req|
        req.headers['Authorization'] = "Basic #{Base64.strict_encode64("#{client_id}:#{client_secret}")}"
        req.body = {
          grant_type: 'refresh_token',
          refresh_token: @integration.refresh_token
        }
      end

      raise "Allegro token refresh failed: #{response.body}" unless response.success?

      data = JSON.parse(response.body)
      expires_at = Time.current + data['expires_in'].to_i.seconds

      @integration.update!(
        access_token: data['access_token'],
        refresh_token: data['refresh_token'],
        expires_at: expires_at
      )

      @integration.access_token
    end

    private

    def client_id
      @integration.client_id.presence || ENV.fetch('ALLEGRO_CLIENT_ID')
    end

    def client_secret
      @integration.client_secret.presence || ENV.fetch('ALLEGRO_CLIENT_SECRET')
    end
  end
end
