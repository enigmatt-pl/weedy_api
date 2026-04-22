module Allegro
  class ProductSearchService
    def initialize(user, query)
      @user = user
      @query = query
      @integration = @user.allegro_integration
    end

    def call
      return { products: [], meta: { total: 0 } } if @query.blank? || @integration.nil?

      begin
        token = Allegro::TokenRefreshService.new(@integration).refresh
        conn = Faraday.new(url: base_api_url)
        response = conn.get('/sale/products') do |req|
          req.headers['Authorization'] = "Bearer #{token}"
          req.headers['Accept'] = 'application/vnd.allegro.public.v1+json'
          req.params['phrase'] = @query.strip
          req.params['limit'] = 20
        end

        return { error: 'Failed to fetch products', detail: response.body } unless response.success?

        data = JSON.parse(response.body) rescue {}
        {
          products: map_products(data['products'] || []),
          meta: { 
            total: data.dig('searchMeta', 'totalCount') || data['totalCount'] || 0
          }
        }
      rescue StandardError => e
        Rails.logger.error("Allegro::ProductSearchService Error: #{e.message}")
        { error: 'Internal search error', detail: e.message }
      end
    end

    private

    def base_api_url
      ENV.fetch('ALLEGRO_ENV', 'sandbox') == 'sandbox' ? 'https://api.allegro.pl.allegrosandbox.pl' : 'https://api.allegro.pl'
    end

    def map_products(products)
      return [] unless products.is_a?(Array)

      products.map do |p|
        cat_id = p.dig('category', 'id') || p['category_id']
        cat_name = p.dig('category', 'name') || p['category_name'] || 'Inne'

        {
          id: p['id'],
          name: p['name'],
          category: {
            id: cat_id,
            name: cat_name
          },
          # Keeping these for backward compatibility during transition
          category_id: cat_id,
          category_name: cat_name,
          image_url: p.dig('images', 0, 'url') || p.dig('mainImage', 'url'),
          parameters: p['parameters'] || []
        }
      end
    end
  end
end
