class AddMasterClassAnalyticsToPageViews < ActiveRecord::Migration[7.1]
  def change
    add_column :page_views, :prefers_reduced_motion, :boolean
    add_column :page_views, :prefers_high_contrast, :boolean
    add_column :page_views, :prefers_forced_colors, :boolean
    add_column :page_views, :is_bot, :boolean
    add_column :page_views, :is_in_app_browser, :boolean
    add_column :page_views, :pdf_viewer_enabled, :boolean
    add_column :page_views, :save_data, :boolean
    add_column :page_views, :perf_fcp_ms, :integer
    add_column :page_views, :perf_lcp_ms, :integer
    add_column :page_views, :perf_ttfb_ms, :integer
    add_column :page_views, :perf_dom_load_ms, :integer
    add_column :page_views, :perf_page_load_ms, :integer
  end
end
