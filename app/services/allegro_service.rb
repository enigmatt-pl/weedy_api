# frozen_string_literal: true

# AllegroService — publishes a Listing as an offer on Allegro via the REST API.
#
# Official docs:
#   Auth:         https://developer.allegro.pl/documentation#tag/Authorization
#   Image upload: POST https://upload.allegro.pl/sale/images
#   Offer create: POST https://api.allegro.pl/sale/product-offers
#
# Usage:
#   result = AllegroService.new(user, listing).call
#   # => { success: true, allegro_offer_id: "..." }
#   # or { success: false, error: "..." }
class AllegroService
  # Category map: use the AI-generated title or fall back to a generic body-parts category.
  # Keys are lowercase substrings to match against listing title.
  CATEGORY_MAP = {
    'drzwi' => '18641', # Doors
    'door' => '18641',
    'klapa' => '18654', # Boot/Trunk lid
    'bagażnik' => '18654',
    'trunk' => '18654',
    'boot' => '18654',
    'zderzak' => '18663', # Bumpers
    'bumper' => '18663',
    'błotnik' => '18635', # Fenders
    'fender' => '18635',
    'wing' => '18635'
  }.freeze

  DEFAULT_CATEGORY_ID = '708' # Części karoserii (fallback)

  # Allegro's mandatory parameter IDs
  PARAM_CONDITION_ID     = '127455' # Stan
  PARAM_CONDITION_USED   = '127455_2' # Used
  PARAM_PART_NUMBER_ID   = '229918' # Numer części / OEM
  PARAM_MANUFACTURER_ID  = '251758' # Producent części

  def initialize(user, listing)
    @user    = user
    @listing = listing
  end

  def call
    validate_token!
    refresh_token! if @user.allegro_token_expired?

    image_urls = upload_images
    offer_id   = create_offer(image_urls)

    @listing.update!(allegro_offer_id: offer_id, status: :published)
    { success: true, allegro_offer_id: offer_id }
  rescue AllegroError => e
    Rails.logger.error("[AllegroService] Error: #{e.message}")
    { success: false, error: e.message }
  end

  private

  # -------------------------------------------------------------------------
  # Token management
  # -------------------------------------------------------------------------

  def validate_token!
    raise AllegroError, 'Allegro not connected' if @user.allegro_integration.nil?
  end

  def refresh_token!
    Allegro::TokenRefreshService.new(@user.allegro_integration).refresh
  end

  # -------------------------------------------------------------------------
  # Image upload
  # -------------------------------------------------------------------------

  # Uploads each Active Storage image to Allegro by providing a public URL.
  # Returns an array of Allegro-hosted image URLs.
  def upload_images
    return [] unless @listing.images.attached?

    # Dynamically generate URLs from actual ActiveStorage blobs,
    # completely bypassing the stale image_urls column.
    actual_image_urls = @listing.images.map do |img|
      @listing.masked_storage_url(img)
    end.compact_blank

    return [] if actual_image_urls.blank?

    actual_image_urls.map do |url|
      upload_single_image(url)
    end.compact_blank
  end

  def upload_single_image(url)
    # Ensure URL is absolute
    full_url = url.start_with?('http') ? url : "#{ENV.fetch('APP_URL', 'https://moto-wrzutka-api.onrender.com')}#{url}"
    
    response = allegro_post(
      uri: upload_uri,
      body: { url: full_url }.to_json,
      headers: {
        'Content-Type' => 'application/vnd.allegro.public.v1+json',
        'Accept' => 'application/vnd.allegro.public.v1+json'
      }
    )
    
    data = parse_json!(response, 'Image upload')
    link = data['url'] || data.dig('image', 'url')
    
    if link.blank?
      Rails.logger.error("[AllegroService] Image upload failed for #{full_url}: #{response.body}")
    else
      Rails.logger.info("[AllegroService] Image uploaded: #{full_url} -> #{link}")
    end
    
    link
  end

  # -------------------------------------------------------------------------
  # Offer creation
  # -------------------------------------------------------------------------

  def create_offer(image_urls)
    payload  = build_offer_payload(image_urls)
    
    # Log the payload for debugging 422 errors
    Rails.logger.info("[AllegroService] Creating offer with payload: #{payload.to_json}")

    response = allegro_post(
      uri: offers_uri,
      body: payload.to_json,
      headers: {
        'Content-Type' => 'application/vnd.allegro.public.v1+json',
        'Accept' => 'application/vnd.allegro.public.v1+json'
      }
    )
    data = parse_json!(response, 'Offer creation')
    # Depending on the response, may be 201 (sync) or 202 (async).
    # In both cases the offer ID is in data['id'].
    data['id'] || raise(AllegroError, "Offer created but no ID returned: #{data.inspect}")
  end

  def build_offer_payload(image_urls)
    payload = {
      name: @listing.title,
      language: 'pl-PL',
      category: { id: resolve_category },
      description: description_section,
      images: (image_urls || []).compact.map { |url| { url: url } },
      sellingMode: {
        format: 'BUY_NOW',
        price: { amount: sprintf('%.2f', @listing.estimated_price.to_f), currency: 'PLN' }
      },
      stock: { available: 1, unit: 'UNIT' },
      publication: { status: 'ACTIVE' },
      location: @user.allegro_location,
      payments: { invoice: 'VAT' },
      parameters: build_parameters,
      external: { id: @listing.id.to_s }
    }

    # If the user linked a specific Allegro product, associate it.
    if @listing.allegro_product_id.present?
      payload[:product] = { id: @listing.allegro_product_id }
    end

    payload
  end

  # Allegro description must be structured as sections with items.
  # Uses TEXT type items — HTML is also accepted but plain text is safest.
  def description_section
    {
      sections: [
        {
          items: [
            { type: 'TEXT', content: @listing.description }
          ]
        }
      ]
    }
  end

  def build_parameters
    [
      # Stan (Condition) — default to Used since these are car parts
      { id: PARAM_CONDITION_ID, valuesIds: [PARAM_CONDITION_USED], values: [], rangeValue: nil },
      # Numer części (OEM Number)
      { id: PARAM_PART_NUMBER_ID, values: [(@listing.oem_number.presence || 'Brak').to_s], valuesIds: [], rangeValue: nil },
      # Producent części (Manufacturer) - Defaulting to "OE" if not detectable
      { id: PARAM_MANUFACTURER_ID, values: [(@listing.market_data&.fetch('manufacturer', nil) || 'OE').to_s], valuesIds: [], rangeValue: nil }
    ]
  end

  # Map listing title to the best matching Allegro leaf category.
  def resolve_category
    return @listing.allegro_category_id if @listing.allegro_category_id.present?

    title_lower = @listing.title.to_s.downcase
    CATEGORY_MAP.each do |keyword, cat_id|
      return cat_id if title_lower.include?(keyword)
    end
    DEFAULT_CATEGORY_ID
  end

  # -------------------------------------------------------------------------
  # HTTP helpers
  # -------------------------------------------------------------------------

  def allegro_post(uri:, body:, headers: {}, basic_auth: false)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.open_timeout = 10
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri.request_uri, headers)

    if basic_auth
      request.basic_auth(allegro_client_id, allegro_client_secret)
    else
      request['Authorization'] = "Bearer #{@user.allegro_integration.access_token}"
    end

    request.body = body
    http.request(request)
  end

  def parse_json!(response, context)
    unless response.is_a?(Net::HTTPSuccess)
      raise AllegroError, "#{context} failed (HTTP #{response.code}): #{response.body}"
    end

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    raise AllegroError, "#{context}: invalid JSON response — #{e.message}"
  end

  # -------------------------------------------------------------------------
  # URI helpers
  # -------------------------------------------------------------------------

  def allegro_base_url
    sandbox? ? 'https://allegro.pl.allegrosandbox.pl' : 'https://allegro.pl'
  end

  def allegro_api_url
    sandbox? ? 'https://api.allegro.pl.allegrosandbox.pl' : 'https://api.allegro.pl'
  end

  def allegro_upload_url
    sandbox? ? 'https://upload.allegro.pl.allegrosandbox.pl' : 'https://upload.allegro.pl'
  end

  def token_uri
    URI("#{allegro_base_url}/auth/oauth/token")
  end

  def upload_uri
    URI("#{allegro_upload_url}/sale/images")
  end

  def offers_uri
    URI("#{allegro_api_url}/sale/product-offers")
  end

  def allegro_redirect_uri
    ENV.fetch('ALLEGRO_REDIRECT_URI', 'http://localhost:3000/allegro/callback')
  end

  def allegro_client_id
    @user.allegro_integration&.client_id.presence || ENV.fetch('ALLEGRO_CLIENT_ID') do
      raise AllegroError, 'User Allegro Client ID not set'
    end
  end

  def allegro_client_secret
    @user.allegro_integration&.client_secret.presence || ENV.fetch('ALLEGRO_CLIENT_SECRET') do
      raise AllegroError, 'User Allegro Client Secret not set'
    end
  end

  def sandbox?
    ENV.fetch('ALLEGRO_ENV', 'sandbox') == 'sandbox'
  end
end

# Custom error class surfaced from AllegroService
class AllegroError < StandardError; end
