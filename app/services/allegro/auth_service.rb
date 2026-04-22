module Allegro
  class AuthService
    def base_url
      ENV.fetch('ALLEGRO_ENV', 'sandbox') == 'sandbox' ? 'https://allegro.pl.allegrosandbox.pl' : 'https://allegro.pl'
    end

    def auth_endpoint
      "#{base_url}/auth/oauth/authorize"
    end

    def token_endpoint
      "#{base_url}/auth/oauth/token"
    end

    def initialize(user)
      @user = user
      @client_id = user.allegro_integration&.client_id.presence || ENV.fetch('ALLEGRO_CLIENT_ID', nil)
      @client_secret = user.allegro_integration&.client_secret.presence || ENV.fetch('ALLEGRO_CLIENT_SECRET', nil)
      @redirect_uri = ENV.fetch('ALLEGRO_REDIRECT_URI', 'http://localhost:5173/dashboard/allegro/callback')

      raise KeyError, 'Missing ALLEGRO_CLIENT_ID' if @client_id.blank?
      raise KeyError, 'Missing ALLEGRO_CLIENT_SECRET' if @client_secret.blank?
    end

    def auth_url
      query = {
        response_type: 'code',
        client_id: @client_id,
        redirect_uri: @redirect_uri,
        prompt: 'confirm'
      }.to_query
      "#{auth_endpoint}?#{query}"
    end

    def exchange_code(code)
      conn = Faraday.new do |f|
        f.request :url_encoded
        f.adapter Faraday.default_adapter
      end

      response = conn.post(token_endpoint) do |req|
        req.headers['Authorization'] = "Basic #{Base64.strict_encode64("#{@client_id}:#{@client_secret}")}"
        req.body = {
          grant_type: 'authorization_code',
          code: code,
          redirect_uri: @redirect_uri
        }
      end

      return { success: false, error: response.body } unless response.success?

      data = JSON.parse(response.body)
      save_integration(data)
      { success: true }
    end

    private

    def save_integration(data)
      expires_at = Time.current + data['expires_in'].to_i.seconds
      integration = @user.allegro_integration || @user.build_allegro_integration
      integration.update!(
        access_token: data['access_token'],
        refresh_token: data['refresh_token'],
        expires_at: expires_at,
        client_id: @client_id,
        client_secret: @client_secret
      )
    end
  end
end
