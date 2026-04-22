require 'rails_helper'

RSpec.describe 'Api::V1::Listings', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    allow_any_instance_of(Api::V1::ListingsController)
      .to receive(:authenticate_user!).and_return(true)
    allow_any_instance_of(Api::V1::ListingsController)
      .to receive(:current_user).and_return(user)
  end

  describe 'GET /api/v1/listings' do
    it 'returns 200 and a paginated JSON response' do
      create_list(:listing, 10, user: user)
      get api_v1_listings_path, params: { page: 1, per_page: 5 }

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json).to have_key('listings')
      expect(json).to have_key('meta')
      expect(json['listings'].length).to eq(5)
      expect(json['meta']['total_count']).to eq(10)
      expect(json['meta']['total_pages']).to eq(2)
    end
  end

  describe 'POST /api/v1/listings/generate' do
    let(:dummy_file) { fixture_file_upload(Rails.root.join('spec/fixtures/files/dummy_image.jpg'), 'image/jpeg') }

    it 'initiates background analysis and returns 202' do
      user.update(credits: 10)

      expect do
        post generate_api_v1_listings_path, params: {
          query_data: 'Some Car Specs',
          images: [dummy_file]
        }
      end.to change(Listing, :count).by(1)
                                    .and change { user.reload.credits }.by(-1)

      expect(response).to have_http_status(:accepted)
      json = response.parsed_body
      expect(json['status']).to eq('generating')
      expect(json).to have_key('id')
    end
  end

  describe 'GET /api/v1/listings/:id' do
    it 'returns the listing details and 200' do
      listing = create(:listing, user: user)
      get api_v1_listing_path(listing)

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['listing']['id']).to eq(listing.id)
    end
  end

  describe 'POST /api/v1/listings' do
    context 'with valid params' do
      it 'creates a listing and returns 201' do
        expect do
          post api_v1_listings_path, params: {
            listing: {
              title: 'Test Part',
              description: 'A good part.',
              estimated_price: 120.0,
              query_data: 'Specs here',
              status: 'draft'
            }
          }
        end.to change(Listing, :count).by(1)

        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json['listing']).to have_key('image_urls')
        expect(json['listing']['query_data']).to eq('Specs here')
      end

      it 'allows duplicate oem_number' do
        create(:listing, user: user, oem_number: 'DUPE123')

        expect do
          post api_v1_listings_path, params: {
            listing: {
              oem_number: 'DUPE123',
              title: 'Test Part 2',
              description: 'Another part.',
              estimated_price: 150.0
            }
          }
        end.to change(Listing, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end
  end

  describe 'PATCH /api/v1/listings/:id' do
    let(:listing) { create(:listing, user: user, title: 'Old Title', description: 'Old Desc', estimated_price: 100.0) }

    it 'updates the listing and returns 200' do
      patch api_v1_listing_path(listing), params: {
        listing: {
          title: 'New Title',
          description: 'New Desc',
          estimated_price: 150.0
        }
      }

      expect(response).to have_http_status(:ok)
      listing.reload
      expect(listing.title).to eq('New Title')
      expect(listing.description).to eq('New Desc')
      expect(listing.estimated_price).to eq(150.0)
    end
  end

  describe 'DELETE /api/v1/listings/:id' do
    it 'destroys the listing' do
      listing = create(:listing, user: user)
      expect do
        delete api_v1_listing_path(listing)
      end.to change(Listing, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
