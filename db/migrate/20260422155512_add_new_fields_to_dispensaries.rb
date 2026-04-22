class AddNewFieldsToDispensaries < ActiveRecord::Migration[7.1]
  def change
    add_column :dispensaries, :city, :string
    
    # Recommendation: Use PostgreSQL array for categories
    add_column :dispensaries, :categories, :text, array: true, default: []
    
    # Coordinates for the map
    add_column :dispensaries, :latitude, :decimal, precision: 10, scale: 6
    add_column :dispensaries, :longitude, :decimal, precision: 10, scale: 6
    
    # Contact & Details
    add_column :dispensaries, :phone, :string
    add_column :dispensaries, :email, :string
    add_column :dispensaries, :website, :string
    add_column :dispensaries, :hours, :text
    add_column :dispensaries, :rating, :decimal, precision: 3, scale: 2, default: 0.0
    
    # Add index for filtering
    add_index :dispensaries, :city
    add_index :dispensaries, :categories, using: 'gin'
  end
end
