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
