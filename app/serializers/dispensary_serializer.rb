# == Schema Information
#
# Table name: listings
#
#  id                  :uuid             not null, primary key
#  description         :text
#  estimated_price     :decimal(10, 2)   default(0.0), not null
#  image_urls          :jsonb
#  market_data         :jsonb
#  oem_number          :string
#  query_data          :text
#  reasoning           :text
#  status              :integer          default("draft"), not null
#  title               :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  allegro_category_id :string
#  allegro_offer_id    :string
#  allegro_product_id  :string
#  user_id             :uuid             not null
#
# Indexes
#
#  index_listings_on_created_at  (created_at)
#  index_listings_on_oem_number  (oem_number)
#  index_listings_on_status      (status)
#  index_listings_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class DispensarySerializer < ActiveModel::Serializer
  attributes :id, :title, :description, :estimated_price, :status, :query_data, :verification_id, :created_at, :image_urls,
             :external_product_id, :platform_product_id, :category_id, :reasoning

  def reasoning
    object.reasoning if scope&.super_admin?
  end
end
