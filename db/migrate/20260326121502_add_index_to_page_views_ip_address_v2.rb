class AddIndexToPageViewsIpAddressV2 < ActiveRecord::Migration[7.1]
  def change
    add_index :page_views, :ip_address, if_not_exists: true
  end
end
