class AddFinalTelemetryToPageViews < ActiveRecord::Migration[7.1]
  def change
    add_column :page_views, :visitor_id, :string
    add_column :page_views, :screen_orientation, :string
    add_column :page_views, :storage_quota_mb, :integer
    add_column :page_views, :storage_usage_mb, :integer
    add_column :page_views, :color_scheme, :string
  end
end
