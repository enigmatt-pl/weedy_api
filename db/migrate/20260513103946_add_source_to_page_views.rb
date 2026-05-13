class AddSourceToPageViews < ActiveRecord::Migration[7.2]
  def change
    # Add source column with default 'js'
    add_column :page_views, :source, :string, default: 'js'
    
    # Ensure is_bot has a default (it already exists)
    change_column_default :page_views, :is_bot, from: nil, to: false
    
    # Add indexes
    add_index :page_views, :source unless index_exists?(:page_views, :source)
    add_index :page_views, :is_bot unless index_exists?(:page_views, :is_bot)
    add_index :page_views, :visitor_id unless index_exists?(:page_views, :visitor_id)
  end
end
