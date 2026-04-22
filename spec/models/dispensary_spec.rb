# == Schema Information
#
# Table name: dispensaries
#
#  id                  :uuid             not null, primary key
#  categories          :text             default([]), is an Array
#  city                :string
#  description         :text
#  email               :string
#  estimated_price     :decimal(10, 2)   default(0.0), not null
#  hours               :text
#  image_urls          :jsonb
#  latitude            :decimal(10, 6)
#  longitude           :decimal(10, 6)
#  market_data         :jsonb
#  phone               :string
#  query_data          :text
#  rating              :decimal(3, 2)    default(0.0)
#  reasoning           :text
#  status              :integer          default("draft"), not null
#  title               :string           not null
#  website             :string
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
#  index_dispensaries_on_categories       (categories) USING gin
#  index_dispensaries_on_city             (city)
#  index_dispensaries_on_created_at       (created_at)
#  index_dispensaries_on_status           (status)
#  index_dispensaries_on_user_id          (user_id)
#  index_dispensaries_on_verification_id  (verification_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Dispensary, type: :model do
  describe 'validations' do
    it 'validates title presence unless generating/failed' do
      dispensary = build(:dispensary, title: nil, status: :draft)
      expect(dispensary).not_to be_valid
      dispensary.status = :generating
      expect(dispensary).to be_valid
    end

    it 'validates description presence unless generating/failed' do
      dispensary = build(:dispensary, description: nil, status: :draft)
      expect(dispensary).not_to be_valid
      dispensary.status = :generating
      expect(dispensary).to be_valid
    end

    it { is_expected.to validate_numericality_of(:estimated_price).is_greater_than_or_equal_to(0) }

    context 'when in generating state' do
      it 'is valid without title/description/price' do
        dispensary = build(:dispensary, :generating)
        expect(dispensary).to be_valid
      end
    end

    context 'when in draft or published state' do
      it 'is invalid without title' do
        dispensary = build(:dispensary, status: :draft, title: nil)
        expect(dispensary).not_to be_valid
      end
    end
  end

  describe 'enums' do
    it {
      expect(subject).to define_enum_for(:status)
        .with_values(draft: 0, published: 1, generating: 2, failed: 3, active: 4, sold: 5, archived: 6)
    }
  end

  describe '#image_urls' do
    it 'returns empty array when no images attached' do
      dispensary = create(:dispensary)
      expect(dispensary.image_urls).to eq([])
    end

    it 'returns array of urls when images are attached' do
      dispensary = create(:dispensary)
      dispensary.images.attach(
        io: Rails.root.join('spec/fixtures/files/dummy_image.jpg').open,
        filename: 'dummy_image.jpg',
        content_type: 'image/jpeg'
      )
      expect(dispensary.image_urls).not_to be_empty
      expect(dispensary.image_urls.first).to include('dummy_image.jpg')
    end
  end
end
