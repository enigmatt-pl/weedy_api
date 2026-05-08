require 'net/http'

class GeoIpLookupService
  def self.lookup(ip)
    new(ip).lookup
  end

  def initialize(ip)
    @ip = ip
    @api_key = ENV.fetch('IPGEOLOCATION_API_KEY', nil)
  end

  def lookup
    return default_response if @ip.blank?

    cached_response || fetch_from_api
  end

  private

  def cached_response
    cached = PageView.where(ip_address: @ip)
                     .where.not(country: nil)
                     .select(:country, :country_code)
                     .first

    return unless cached

    {
      country: cached.country,
      country_code: cached.country_code
    }
  end

  def fetch_from_api
    return default_response if @api_key.blank?

    begin
      geo_data = fetch_external_data
      {
        country: geo_data['country_name'] || 'Unknown',
        country_code: geo_data['country_code2'] || '??'
      }
    rescue StandardError => e
      Rails.logger.error "GeoIP Service Failure: #{e.message}"
      default_response
    end
  end

  def fetch_external_data
    uri = URI("https://api.ipgeolocation.io/ipgeo?apiKey=#{@api_key}&ip=#{@ip}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 2
    http.read_timeout = 2

    response = http.get(uri.request_uri)
    return {} unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end

  def default_response
    { country: 'Unknown', country_code: '??' }
  end
end
