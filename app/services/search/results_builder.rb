# frozen_string_literal: true

module Search
  class ResultsBuilder
    PERMITTED_PARAMS = %w[q city category order page per_page].freeze

    ORDER_OPTIONS = %w[relevance rating_desc rating_asc].freeze

    # Columns we full-text search against
    SEARCH_COLUMNS = %w[title description city categories::text query_data].freeze

    def initialize(params:, user: nil)
      @params = sanitize_params(params)
      @query   = @params['q'].to_s.strip
      @city    = @params['city'].to_s.strip.presence
      @category = @params['category'].to_s.strip.presence
      @order   = ORDER_OPTIONS.include?(@params['order']) ? @params['order'] : 'relevance'
      @page    = (@params['page'] || 1).to_i
      @per_page = [(@params['per_page'] || 20).to_i, 100].min
      @user    = user
      @results = []
    end

    def fetch
      build_base_scope
      apply_text_filter
      apply_city_filter
      apply_category_filter
      apply_ordering
      paginate
      build_json
    end

    attr_reader :params, :query, :city, :category, :order, :page, :per_page, :user, :results, :scope

    private

    def build_base_scope
      @scope = Dispensary.publicly_visible
                         .with_attached_images
                         .includes(:user)
    end

    # ILIKE across all search columns joined with OR
    def apply_text_filter
      return if query.blank?

      conditions = SEARCH_COLUMNS.map { |col| "#{col} ILIKE ?" }.join(' OR ')
      bindings = SEARCH_COLUMNS.map { "%#{query}%" }
      @scope = scope.where(conditions, *bindings)
    end

    def apply_city_filter
      return if city.blank?

      @scope = scope.where('city ILIKE ?', "%#{city}%")
    end

    def apply_category_filter
      return if category.blank?

      @scope = scope.where('categories::text ILIKE ?', "%#{category}%")
    end

    def apply_ordering
      @scope = case order
               when 'rating_desc'
                 scope.order(rating: :desc, created_at: :desc)
               when 'rating_asc'
                 scope.order(rating: :asc, created_at: :desc)
               else
                 # Default: relevance — prioritise title match, then rating
                 if query.present?
                   scope.order(
                     Arel.sql("CASE WHEN title ILIKE #{ActiveRecord::Base.connection.quote("%#{query}%")} THEN 0 ELSE 1 END"),
                     rating: :desc,
                     created_at: :desc
                   )
                 else
                   scope.order(rating: :desc, created_at: :desc)
                 end
               end
    end

    def paginate
      @scope = scope.page(page).per(per_page)
    end

    def build_json
      {
        query:,
        city:,
        category:,
        order:,
        results: build_results,
        meta: pagination_meta
      }
    end

    def build_results
      scope.map do |dispensary|
        {
          id: dispensary.id,
          title: dispensary.title,
          description: dispensary.description,
          city: dispensary.city,
          latitude: dispensary.latitude,
          longitude: dispensary.longitude,
          categories: dispensary.categories,
          rating: dispensary.rating,
          phone: dispensary.phone,
          email: dispensary.email,
          website: dispensary.website,
          hours: dispensary.hours,
          image_urls: dispensary.image_urls,
          status: dispensary.status
        }
      end
    end

    def pagination_meta
      {
        current_page: scope.current_page,
        next_page: scope.next_page,
        prev_page: scope.prev_page,
        total_pages: scope.total_pages,
        total_count: scope.total_count
      }
    end

    def sanitize_params(raw_params)
      raw_params.select { |k, _v| PERMITTED_PARAMS.include?(k.to_s) }
    end
  end
end
