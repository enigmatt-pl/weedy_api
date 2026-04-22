class AddCpuDetailsToPageViews < ActiveRecord::Migration[7.1]
  def change
    add_column :page_views, :cpu_architecture, :string
    add_column :page_views, :device_model, :string
    add_column :page_views, :platform, :string
    add_column :page_views, :vendor, :string
  end
end
