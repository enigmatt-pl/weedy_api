require 'net/http'

module Api
  module V1
    class AnalyticsController < ActionController::API
      include ActionController::HttpAuthentication::Basic::ControllerMethods
      
      before_action :authenticate_analytics!

      def create
        ip = request.remote_ip
        geo_data = GeoIpLookupService.lookup(ip)

        begin
          # Fuzzed payload decoding: reverse string -> base64 decode -> parse JSON
          raw_payload = params[:pd].to_s.reverse
          decoded = Base64.decode64(raw_payload)
          parsed_data = JSON.parse(decoded)
        rescue => e
          Rails.logger.warn "Failed to parse fuzzed payload: #{e.message}"
          return head :bad_request
        end
        
        # Permit all keys from the parsed hash for our attributes
        permitted_data = ActionController::Parameters.new(parsed_data).permit(
          :visitor_id, :path, :referrer, :user_agent, :browser_name, :browser_version,
          :os_name, :os_version, :language, :languages, :timezone, :timezone_offset_minutes,
          :screen_width, :screen_height, :screen_color_depth, :device_pixel_ratio,
          :viewport_width, :viewport_height, :connection_type, :connection_effective_type,
          :connection_downlink_mbps, :connection_rtt_ms, :hardware_concurrency,
          :device_memory_gb, :max_touch_points, :page_title, :session_storage_available,
          :local_storage_available, :cookies_enabled, :do_not_track, :js_heap_size_mb,
          :gpu_vendor, :gpu_renderer, :battery_level, :battery_charging,
          :storage_quota_mb, :storage_usage_mb, :color_scheme, :screen_orientation,
          :cpu_architecture, :device_model, :platform, :vendor,
          :prefers_reduced_motion, :prefers_high_contrast, :prefers_forced_colors,
          :is_bot, :is_in_app_browser, :pdf_viewer_enabled, :save_data,
          :perf_fcp_ms, :perf_lcp_ms, :perf_ttfb_ms, :perf_dom_load_ms, :perf_page_load_ms,
          :is_touch_device
        )

        PageView.create!(
          permitted_data.merge(
            ip_address: ip,
            country: geo_data[:country],
            country_code: geo_data[:country_code]
          )
        )
        head :created
      rescue => e
        Rails.logger.error "Analytics Error: #{e.message}"
        head :ok # Don't break the frontend if DB fails
      end

      private

      def authenticate_analytics!
        # Handle both standard Basic Auth and the ?_auth URL param for sendBeacon
        auth_token = params[:_auth]
        
        if auth_token.present?
          begin
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
