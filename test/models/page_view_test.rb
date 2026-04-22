# == Schema Information
#
# Table name: page_views
#
#  id                        :uuid             not null, primary key
#  battery_charging          :boolean
#  battery_level             :float
#  browser_name              :string
#  browser_version           :string
#  click_count               :integer
#  color_scheme              :string
#  connection_downlink_mbps  :float
#  connection_effective_type :string
#  connection_rtt_ms         :integer
#  connection_type           :string
#  cookies_enabled           :boolean
#  country                   :string
#  country_code              :string
#  cpu_architecture          :string
#  device_memory_gb          :float
#  device_model              :string
#  device_pixel_ratio        :float
#  do_not_track              :string
#  exit_intent               :boolean
#  gpu_renderer              :string
#  gpu_vendor                :string
#  hardware_concurrency      :integer
#  ip_address                :string
#  is_bot                    :boolean
#  is_in_app_browser         :boolean
#  is_touch_device           :boolean
#  js_heap_size_mb           :integer
#  language                  :string
#  languages                 :string
#  local_storage_available   :boolean
#  max_touch_points          :integer
#  os_name                   :string
#  os_version                :string
#  page_title                :string
#  path                      :string
#  pdf_viewer_enabled        :boolean
#  perf_dom_load_ms          :integer
#  perf_fcp_ms               :integer
#  perf_lcp_ms               :integer
#  perf_page_load_ms         :integer
#  perf_ttfb_ms              :integer
#  platform                  :string
#  prefers_forced_colors     :boolean
#  prefers_high_contrast     :boolean
#  prefers_reduced_motion    :boolean
#  referrer                  :string
#  save_data                 :boolean
#  screen_color_depth        :integer
#  screen_height             :integer
#  screen_orientation        :string
#  screen_width              :integer
#  scroll_depth_pct          :integer
#  scroll_milestones         :string
#  session_storage_available :boolean
#  storage_quota_mb          :integer
#  storage_usage_mb          :integer
#  time_on_page_sec          :integer
#  timezone                  :string
#  timezone_offset_minutes   :integer
#  user_agent                :string
#  vendor                    :string
#  viewport_height           :integer
#  viewport_width            :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  visitor_id                :string
#
# Indexes
#
#  index_page_views_on_ip_address  (ip_address)
#
require "test_helper"

class PageViewTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
