require 'faraday'
require 'faraday/retry'
require 'json'
require 'base64'
require 'stringio'

class GeminiMegaPromptClient
  # Using the user-confirmed 2.5-flash endpoint
  API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent'.freeze

  def initialize
    @api_key = ENV.fetch('GEMINI_API_KEY')
  end

  def generate(prompt_text, images = [])
    conn = Faraday.new do |f|
      f.request :retry, {
        max: 3,
        interval: 2,
        interval_randomness: 0.5,
        backoff_factor: 2,
        retry_statuses: [429, 503],
        methods: [:post]
      }
      f.request :json
      f.response :json
    end

    payload = build_payload(prompt_text, images)
    response = conn.post("#{API_URL}?key=#{@api_key}", payload)

    unless response.success?
      error_msg = "Gemini API Error: #{response.status} - #{response.body.inspect}"
      Rails.logger.error(error_msg)
      raise error_msg
    end

    output_text = parse_response(response.body)
    
    # Quiet the production logs to avoid bloat, but preserve full visibility in development.
    if Rails.env.development? || ENV['DEBUG_AI'] == 'true'
      Rails.logger.info("Gemini Output [#{response.status}]: #{output_text}")
    else
      Rails.logger.info("Gemini Response SUCCESS [#{response.status}] - Size: #{output_text.to_s.length} chars")
    end

    output_text
  end

  def fallback_image_data(image)
    if image.respond_to?(:download)
      image.download
    elsif image.respond_to?(:read)
      image.rewind
      image.read
    else
      image
    end
  rescue StandardError
    nil
  end

  private

  def build_payload(prompt_text, images)
    parts = [{ text: prompt_text }]

    # Process each image to ensure it stays within Gemini's 20MB request limit
    images.each { |img| parts << extract_image_data(img) }

    {
      contents: [{ role: 'user', parts: parts.compact }],
      generationConfig: {
        temperature: 0.0
      }
    }
  end

  def extract_image_data(image)
    return nil unless image

    # Use ActiveStorage's open block if available, which handles tempfiles efficiently
    # and works well with ImageProcessing.
    processed_data = nil

    begin
      if image.respond_to?(:open)
        image.open do |file|
          processed_data = optimize_image(file.path)
        end
      else
        # Fallback for IO-like objects or raw strings
        raw_data = if image.respond_to?(:download)
                     image.download
                   elsif image.respond_to?(:read)
                     image.rewind if image.respond_to?(:rewind)
                     image.read
                   else
                     image
                   end
        processed_data = optimize_image_from_memory(raw_data)
      end
    rescue StandardError => e
      Rails.logger.error("GeminiClient: Optimization failed: #{e.message}")
      processed_data = fallback_image_data(image)
    end

    return nil if processed_data.blank?

    {
      inline_data: {
        mime_type: 'image/jpeg',
        data: Base64.strict_encode64(processed_data)
      }
    }
  end

  def optimize_image(source_path)
    processor = defined?(ImageProcessing::Vips) ? ImageProcessing::Vips : ImageProcessing::MiniMagick

    optimized = processor
                .source(source_path)
                .resize_to_limit(1200, 1200)
                .convert('jpg')
                .saver(quality: 80)
                .call

    data = File.binread(optimized.path)
    optimized.close! if optimized.respond_to?(:close!)

    Rails.logger.info("GeminiClient: Optimization SUCCESS. Size: #{data.bytesize} bytes.")
    data
  end

  def optimize_image_from_memory(raw_data)
    return nil if raw_data.blank?

    Rails.logger.info("GeminiClient: Processing from memory. Raw size: #{raw_data.bytesize} bytes.")

    processor = defined?(ImageProcessing::Vips) ? ImageProcessing::Vips : ImageProcessing::MiniMagick

    # Use a StringIO for memory-based data
    optimized = processor
                .source(StringIO.new(raw_data))
                .resize_to_limit(1200, 1200)
                .convert('jpg')
                .saver(quality: 80)
                .call

    data = File.binread(optimized.path)
    optimized.close! if optimized.respond_to?(:close!)
    data
  end

  def parse_response(body)
    body.dig('candidates', 0, 'content', 'parts', 0, 'text') || '{}'
  end
end
