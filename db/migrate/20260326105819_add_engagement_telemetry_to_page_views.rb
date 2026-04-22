class AddEngagementTelemetryToPageViews < ActiveRecord::Migration[7.1]
  def change
    add_column :page_views, :is_touch_device, :boolean
    add_column :page_views, :scroll_depth_pct, :integer
    add_column :page_views, :scroll_milestones, :string
    add_column :page_views, :time_on_page_sec, :integer
    add_column :page_views, :click_count, :integer
    add_column :page_views, :exit_intent, :boolean
  end
end
