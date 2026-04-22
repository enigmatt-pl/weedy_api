class CreatePageViews < ActiveRecord::Migration[7.1]
  def change
    create_table :page_views, id: :uuid do |t|
      t.string :path
      t.string :referrer
      t.string :user_agent
      t.string :browser_name
      t.string :browser_version
      t.string :os_name
      t.string :os_version
      t.string :language
      t.string :languages
      t.string :timezone
      t.integer :timezone_offset_minutes
      t.integer :screen_width
      t.integer :screen_height
      t.integer :screen_color_depth
      t.float :device_pixel_ratio
      t.integer :viewport_width
      t.integer :viewport_height
      t.string :connection_type
      t.string :connection_effective_type
      t.float :connection_downlink_mbps
      t.integer :connection_rtt_ms
      t.integer :hardware_concurrency
      t.float :device_memory_gb
      t.integer :max_touch_points
      t.string :page_title
      t.boolean :session_storage_available
      t.boolean :local_storage_available
      t.boolean :cookies_enabled
      t.string :do_not_track
      t.integer :js_heap_size_mb
      t.string :ip_address

      t.timestamps
    end
  end
end
