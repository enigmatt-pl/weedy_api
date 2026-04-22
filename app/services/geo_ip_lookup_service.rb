require 'net/http'

class GeoIpLookupService
  def self.lookup(ip)
    new(ip).lookup
  end

  def initialize(ip)
    @ip = ip
    @api_key = ENV['IPGEOLOCATION_API_KEY']
  end

  def lookup
    return { country: "Unknown", country_code: "??" } if @ip.blank?

    # 1. Try to get from local database cache first to save API credits
    cached = PageView.where(ip_address: @ip)
                     .where.not(country: nil)
                     .select(:country, :country_code)
                     .first
    
    if cached
      return { 
        country: cached.country, 
        country_code: cached.country_code 
      }
    end

    # 2. If not found, fetch from external API
    return { country: "Unknown", country_code: "??" } if @api_key.blank?

    begin
      uri = URI("https://api.ipgeolocation.io/ipgeo?apiKey=#{@api_key}&ip=#{@ip}")
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 2
      http.read_timeout = 2
      
      response = http.get(uri.request_uri)
      return { country: "Unknown", country_code: "??" } unless response.is_a?(Net::HTTPSuccess)

      geo_data = JSON.parse(response.body)
      
      {
        country: geo_data['country_name'] || "Unknown",
        country_code: geo_data['country_code2'] || "??"
      }
    rescue => e
      Rails.logger.error "GeoIP Service Failure: #{e.message}"
      { country: "Unknown", country_code: "??" }
    end
  end
end
