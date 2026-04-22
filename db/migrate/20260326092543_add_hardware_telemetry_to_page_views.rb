class AddHardwareTelemetryToPageViews < ActiveRecord::Migration[7.1]
  def change
    add_column :page_views, :gpu_vendor, :string
    add_column :page_views, :gpu_renderer, :string
    add_column :page_views, :battery_level, :float
    add_column :page_views, :battery_charging, :boolean
  end
end
