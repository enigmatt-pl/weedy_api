require 'rails_helper'

RSpec.describe AllegroService do
  let(:user) { create(:user) }
  let(:listing) { create(:listing, user: user, title: 'Drzwi BMW', oem_number: '123456', estimated_price: 500) }
  let(:service) { described_class.new(user, listing) }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('ALLEGRO_CLIENT_ID').and_return('test_id')
    allow(ENV).to receive(:fetch).with('ALLEGRO_CLIENT_SECRET').and_return('test_secret')
    allow(ENV).to receive(:fetch).with('ALLEGRO_REDIRECT_URI', anything).and_return('http://test.com/callback')
    allow(ENV).to receive(:fetch).with('ALLEGRO_ENV', 'sandbox').and_return('sandbox')
    allow(ENV).to receive(:fetch).with('APP_HOST', anything).and_return('localhost:3000')
    create(:allegro_integration, user: user, access_token: 'valid_token', refresh_token: 'refresh', expires_at: 1.hour.from_now)
  end

  describe '#call' do
    context 'when token is expired' do
      before do
        user.allegro_integration.update(expires_at: 1.hour.ago)

        # Mocking Refresh Token Response
        stub_request(:post, %r{auth/oauth/token})
          .to_return(status: 200, body: {
            access_token: 'new_token',
            refresh_token: 'new_refresh',
            expires_in: 3600
          }.to_json)

        # Mock subsequent calls
        stub_request(:post, %r{sale/images})
          .to_return(status: 200, body: { url: 'http://allegro.img/1' }.to_json)
        stub_request(:post, %r{sale/product-offers})
          .to_return(status: 201, body: { id: 'offer_123' }.to_json)
      end

      it 'refreshes the token before proceeding' do
        result = service.call
        expect(result[:success]).to be true
        expect(user.allegro_integration.reload.access_token).to eq('new_token')
        expect(user.allegro_integration.refresh_token).to eq('new_refresh')
      end
    end

    context 'when successful' do
      before do
        # Mock image upload
        stub_request(:post, %r{sale/images})
          .to_return(status: 200, body: { url: 'http://allegro.img/1' }.to_json)

        # Mock offer creation
        stub_request(:post, %r{sale/product-offers})
          .to_return(status: 201, body: { id: 'offer_123' }.to_json)
      end

      it 'returns success and updates listing' do
        result = service.call
        expect(result[:success]).to be true
        expect(result[:allegro_offer_id]).to eq('offer_123')
        expect(listing.reload.status).to eq('published')
      end

      it 'picks the correct category based on title' do
        expect(service.send(:resolve_category)).to eq('18641')
      end
    end

    context 'when Allegro API returns error' do
      before do
        # Attach an image to ensure it tries to upload
        listing.images.attach(
          io: Rails.root.join('spec/fixtures/files/dummy_image.jpg').open,
          filename: 'dummy.jpg'
        )
        stub_request(:post, %r{sale/images}).to_return(status: 500, body: 'Internal Error')
      end

      it 'returns failure with error message' do
        result = service.call
        expect(result[:success]).to be false
        expect(result[:error]).to include('Image upload failed (HTTP 500)')
      end
    end
  end
end
