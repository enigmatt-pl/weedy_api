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
class Dispensary < ApplicationRecord
  include StorageMaskable

  belongs_to :user
  attribute :reasoning, :text
  has_many_attached :images

  enum :status, { draft: 0, published: 1, generating: 2, failed: 3, active: 4, archived: 6 }, default: :draft

  validates :title, presence: true, unless: -> { generating? || failed? }
  validates :estimated_price, numericality: { greater_than_or_equal_to: 0 }
  validates :description, presence: true, unless: -> { generating? || failed? }

  def image_urls
    return images.filter_map { |img| masked_storage_url(img) } if images.attached?

    self[:image_urls] || []
  end
end
