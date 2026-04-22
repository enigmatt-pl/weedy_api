class AddLocationToPageViews < ActiveRecord::Migration[7.1]
  def change
    add_column :page_views, :country, :string
    add_column :page_views, :country_code, :string
  end
end
