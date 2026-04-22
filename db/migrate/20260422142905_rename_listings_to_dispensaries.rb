class RenameListingsToDispensaries < ActiveRecord::Migration[7.1]
  def change
    rename_table :listings, :dispensaries
    rename_column :dispensaries, :oem_number, :verification_id
    rename_column :dispensaries, :allegro_offer_id, :platform_product_id
    rename_column :dispensaries, :allegro_product_id, :external_product_id
    rename_column :dispensaries, :allegro_category_id, :category_id
  end
end
