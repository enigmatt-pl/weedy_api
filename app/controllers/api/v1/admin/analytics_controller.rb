module Api
  module V1
    module Admin
      class AnalyticsController < ApplicationController
        before_action :authenticate_super_admin!

        def page_views
          # 1. Start with the full list
          views = PageView.order(created_at: :desc)
          
          # 2. Filters
          if params[:search].present?
            query = "%#{params[:search]}%"
            views = views.where(
              "path LIKE ? OR ip_address LIKE ? OR visitor_id LIKE ?", 
              query, query, query
            )
          end
          
          views = views.where(language: params[:language]) if params[:language].present?
          views = views.where(country_code: params[:country]) if params[:country].present?
          
          # 3. Paginate the (now filtered) results
          @views = views.page(params[:page]).per(params[:per_page] || 50)
          
          render json: {
            page_views: @views,
            meta: { 
              current_page: @views.current_page, 
              total_pages: @views.total_pages, 
              total_count: @views.total_count 
            }
          }
        end

        def summary
          render json: {
            total_views: PageView.count,
            unique_paths: PageView.distinct.count(:path),
            views_today: PageView.where('created_at >= ?', Time.zone.now.beginning_of_day).count,
            views_this_week: PageView.where('created_at >= ?', 1.week.ago).count,
            
            # FOR THE GRAPH (Last 7 Days)
            daily_activity: PageView.where('created_at >= ?', 7.days.ago)
                                     .group("DATE(created_at)")
                                     .count
                                     .map { |date, count| { date: date, count: count } },
            
            # FOR THE FILTER DROPDOWNS
            available_languages: PageView.distinct.pluck(:language).compact,
            available_countries: PageView.where.not(country: nil)
                                         .distinct.pluck(:country, :country_code)
                                         .map { |name, code| { name: name, code: code } },
            
            top_paths: PageView.group(:path).order('count_all DESC').limit(8).count.map { |k, v| { path: k, count: v } },
            top_referrers: PageView.group(:referrer).order('count_all DESC').limit(8).count.map { |k, v| { referrer: k, count: v } }
          }
        end
      end
    end
  end
end
