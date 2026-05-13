require 'base64'

# app/middleware/analytics_tracker.rb
class AnalyticsTracker
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    
    # Capture hit if it's a page-like request and not an asset
    if request.get? && !request.path.start_with?('/assets', '/api/v1/health', '/api/v1/admin')
      # Extract Real IP (Respect Cloudflare)
      ip = env['HTTP_CF_CONNECTING_IP'] || request.ip
      
      # Detect Bot
      is_bot = BotDetectionService.bot?(request.user_agent)
      
      # Async Log (or use Background Job)
      # Note: Using .create here as requested, though backgrounding would be better for perf.
      # We check path for /px for the pixel source.
      PageView.create(
        ip_address: ip,
        path: request.path,
        user_agent: request.user_agent,
        is_bot: is_bot,
        source: request.path == '/px' ? 'pixel' : 'server'
      )
    end

    # Return 1x1 Pixel if path is /px
    return pixel_response if request.path == '/px'

    @app.call(env)
  end

  private

  def pixel_response
    [200, { 'Content-Type' => 'image/gif' }, [Base64.decode64("R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7")]]
  end
end
