require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe ListingWorker, type: :worker do
  let(:user) { create(:user) }
  let(:listing) { create(:listing, :generating, user: user) }

  describe '#perform' do
    it 'updates the listing status to draft after successful generation' do
      allow_any_instance_of(ListingGeneratorService).to receive(:call).and_return({
        title: 'Async Title',
        description: 'Async Description',
        estimated_price: 300,
        reasoning: 'Async reasoning'
      }.with_indifferent_access)

      described_class.new.perform(listing.id)

      listing.reload
      expect(listing.status).to eq('draft')
      expect(listing.title).to eq('Async Title')
      expect(listing.estimated_price).to eq(300)
    end

    it 'marks the listing as failed on error' do
      allow_any_instance_of(ListingGeneratorService).to receive(:call).and_raise(StandardError, 'Gemini failed')

      described_class.new.perform(listing.id)

      expect(listing.reload.status).to eq('failed')
    end
  end
end
