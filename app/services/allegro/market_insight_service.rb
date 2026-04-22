module Allegro
  class MarketInsightService
    def initialize(query)
      @query = query
      @client_id = ENV['ALLEGRO_CLIENT_ID']
      @client_secret = ENV['ALLEGRO_CLIENT_SECRET']
      @env = ENV.fetch('ALLEGRO_ENV', 'sandbox')
    end

    def call
      return [] if @query.blank? || @client_id.blank?

      token = get_token
      return [] unless token

      fetch_offers(token)
    end

    private

    def get_token
      Rails.cache.fetch("allegro_client_credentials_token_#{@env}", expires_in: 11.hours) do
        authenticate
      end
    end

    def authenticate
      Rails.logger.info "[Allegro::MarketInsightService] 🔑 Authenticating via client_credentials..."
      conn = Faraday.new(url: auth_base_url)
      response = conn.post('/auth/oauth/token') do |req|
        req.headers['Authorization'] = "Basic #{Base64.strict_encode64("#{@client_id}:#{@client_secret}")}" 
        req.params['grant_type'] = 'client_credentials'
      end

      unless response.success?
        Rails.logger.error "[Allegro::MarketInsightService] ❌ Auth Failed! Status: #{response.status}, Body: #{response.body}"
        return nil
      end

      Rails.logger.info "[Allegro::MarketInsightService] ✅ Auth Successful."
      JSON.parse(response.body)['access_token']
    rescue StandardError => e
      Rails.logger.error "[Allegro::MarketInsightService] ❌ Auth Exception: #{e.message}"
      nil
    end

    def fetch_offers(token)
      Rails.logger.info "[Allegro::MarketInsightService] 🔎 Fetching offers for phrase: #{@query.inspect}"
      conn = Faraday.new(url: api_base_url)
      response = conn.get('/offers/listing') do |req|
        req.headers['Authorization'] = "Bearer #{token}"
        req.headers['Accept'] = 'application/vnd.allegro.public.v1+json'
        # Filter for used parts if possible, but Allegro API phrase search is quite powerful
        req.params['phrase'] = @query
        req.params['fallback'] = false 
        req.params['limit'] = 20
      end

      unless response.success?
        Rails.logger.error "[Allegro::MarketInsightService] ❌ Fetch Failed! Status: #{response.status}, Body: #{response.body}"
        return []
      end

      data = JSON.parse(response.body)
      count = (data.dig('items', 'regular')&.size.to_i + data.dig('items', 'promoted')&.size.to_i)
      Rails.logger.info "[Allegro::MarketInsightService] ✅ Received #{count} items from Allegro API."
      parse_results(data)
    rescue StandardError => e
      Rails.logger.error "[Allegro::MarketInsightService] ❌ Fetch Exception: #{e.message}"
      []
    end

    def parse_results(data)
      # Reguł i Promowane
      items = (data.dig('items', 'regular') || []) + (data.dig('items', 'promoted') || [])
      
      items.map do |item|
        {
          title: item['name'],
          price: item.dig('sellingMode', 'price', 'amount'),
          source: 'Allegro REST API'
        }
      end
    end

    def auth_base_url
      @env == 'sandbox' ? 'https://allegro.pl.allegrosandbox.pl' : 'https://allegro.pl'
    end

    def api_base_url
      @env == 'sandbox' ? 'https://api.allegro.pl.allegrosandbox.pl' : 'https://api.allegro.pl'
    end
  end
end
