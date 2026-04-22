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
require 'rails_helper'

RSpec.describe Listing, type: :model do
  describe 'validations' do
    it 'validates title presence unless generating/failed' do
      listing = build(:listing, title: nil, status: :draft)
      expect(listing).not_to be_valid
      listing.status = :generating
      expect(listing).to be_valid
    end

    it 'validates description presence unless generating/failed' do
      listing = build(:listing, description: nil, status: :draft)
      expect(listing).not_to be_valid
      listing.status = :generating
      expect(listing).to be_valid
    end

    it { is_expected.to validate_numericality_of(:estimated_price).is_greater_than_or_equal_to(0) }

    it 'requires oem_number when query_data is blank' do
      listing = build(:listing, oem_number: nil, query_data: nil)
      expect(listing).not_to be_valid
      expect(listing.errors[:oem_number]).to include("can't be blank")
    end

    it 'allows blank oem_number when query_data is present' do
      listing = build(:listing, oem_number: nil, query_data: 'Some specs')
      expect(listing).to be_valid
    end

    context 'when in generating state' do
      it 'is valid without title/description/price' do
        listing = build(:listing, :generating)
        expect(listing).to be_valid
      end
    end

    context 'when in draft or published state' do
      it 'is invalid without title/description/price' do
        listing = build(:listing, status: :draft, title: nil)
        expect(listing).not_to be_valid
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
      listing = create(:listing)
      expect(listing.image_urls).to eq([])
    end

    it 'returns array of urls when images are attached' do
      listing = create(:listing)
      listing.images.attach(
        io: Rails.root.join('spec/fixtures/files/dummy_image.jpg').open,
        filename: 'dummy_image.jpg',
        content_type: 'image/jpeg'
      )
      expect(listing.image_urls).not_to be_empty
      expect(listing.image_urls.first).to include('dummy_image.jpg')
    end
  end
end
