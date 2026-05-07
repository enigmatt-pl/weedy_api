# frozen_string_literal: true

module Api
  module V1
    class SearchesController < ApplicationController
      # No authentication required — searches are public.
      # current_user will be populated if a token is present (for attribution).

      # POST /api/v1/searches
      # Creates a persistent search record and returns its UUID + results.
      def create
        builder = ::Search::ResultsBuilder.new(params: search_params, user: current_user)
        payload = builder.fetch

        search = ::Search.create!(
          query: builder.query,
          city: builder.city,
          category: builder.category,
          order: builder.order,
          filters: extra_filters,
          results_count: payload[:meta][:total_count],
          ip_address: request.remote_ip,
          user_agent: request.user_agent,
          user: current_user
        )

        render json: payload.merge(search_id: search.id), status: :created
      end

      # GET /api/v1/searches/:id
      # Re-runs the search for a persisted search record so the user can
      # bookmark / share the URL (results may differ as new dispensaries appear).
      def show
        search = ::Search.find(params[:id])

        builder = ::Search::ResultsBuilder.new(
          params: {
            'q'        => search.query,
            'city'     => search.city,
            'category' => search.category,
            'order'    => search.order,
            'page'     => params[:page],
            'per_page' => params[:per_page]
          }.compact,
          user: current_user
        )

        payload = builder.fetch
        render json: payload.merge(search_id: search.id, original_search_at: search.created_at)
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Search not found' }, status: :not_found
      end

      private

      def search_params
        params.permit(:q, :city, :category, :order, :page, :per_page).to_h
      end

      # Any additional filter params outside the core set are stored as-is for analytics
      def extra_filters
        params.except(:q, :city, :category, :order, :page, :per_page,
                       :format, :controller, :action).to_unsafe_h.select do |k, _|
          k.to_s !~ /^_/
        end
      end
    end
  end
end
