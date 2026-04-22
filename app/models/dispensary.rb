# == Schema Information
#
# Table name: dispensaries
#
#  id                  :uuid             not null, primary key
#  description         :text
#  estimated_price     :decimal(10, 2)   default(0.0), not null
#  image_urls          :jsonb
#  market_data         :jsonb
#  query_data          :text
#  reasoning           :text
#  status              :integer          default("draft"), not null
#  title               :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  category_id         :string
#  external_product_id :string
#  platform_product_id :string
#  user_id             :uuid             not null
#  verification_id     :string
#
# Indexes
#
#  index_dispensaries_on_created_at       (created_at)
#  index_dispensaries_on_status           (status)
#  index_dispensaries_on_user_id          (user_id)
#  index_dispensaries_on_verification_id  (verification_id)
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
