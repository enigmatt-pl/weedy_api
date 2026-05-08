require 'rails_helper'

RSpec.describe 'Api::V1::Dispensaries', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    allow_any_instance_of(Api::V1::DispensariesController)
      .to receive(:authenticate_user!).and_return(true)
    allow_any_instance_of(Api::V1::DispensariesController)
      .to receive(:current_user).and_return(user)
  end

  describe 'GET /api/v1/dispensaries' do
    it 'returns 200 and a paginated JSON response' do
      create_list(:dispensary, 10, user: user)
      get api_v1_dispensaries_path, params: { page: 1, per_page: 5 }

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json).to have_key('dispensaries')
      expect(json).to have_key('meta')
      expect(json['dispensaries'].length).to eq(5)
      expect(json['meta']['total_count']).to eq(10)
      expect(json['meta']['total_pages']).to eq(2)
    end
  end

  describe 'GET /api/v1/dispensaries/:id' do
    it 'returns the dispensary details and 200' do
      dispensary = create(:dispensary, user: user)
      get api_v1_dispensary_path(dispensary)

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['dispensary']['id']).to eq(dispensary.id)
    end
  end

  describe 'POST /api/v1/dispensaries' do
    context 'with valid params' do
      it 'creates a dispensary and returns 201' do
        expect do
          post api_v1_dispensaries_path, params: {
            dispensary: {
              title: 'Test Dispensary',
              description: 'A good shop.',
              estimated_price: 120.0,
              query_data: 'Specs here',
              status: 'draft'
            }
          }
        end.to change(Dispensary, :count).by(1)

        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json['dispensary']).to have_key('image_urls')
        expect(json['dispensary']['query_data']).to eq('Specs here')
      end
    end
  end

  describe 'PATCH /api/v1/dispensaries/:id' do
    let(:dispensary) { create(:dispensary, user: user, title: 'Old Title', description: 'Old Desc', estimated_price: 100.0) }

    it 'updates the dispensary and returns 200' do
      patch api_v1_dispensary_path(dispensary), params: {
        dispensary: {
          title: 'New Title',
          description: 'New Desc',
          estimated_price: 150.0
        }
      }

      expect(response).to have_http_status(:ok)
      dispensary.reload
      expect(dispensary.title).to eq('New Title')
      expect(dispensary.description).to eq('New Desc')
      expect(dispensary.estimated_price.to_f).to eq(150.0)
    end
  end

  describe 'DELETE /api/v1/dispensaries/:id' do
    it 'destroys the dispensary' do
      dispensary = create(:dispensary, user: user)
      expect do
        delete api_v1_dispensary_path(dispensary)
      end.to change(Dispensary, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'POST /api/v1/dispensaries/:id/publish' do
    it 'publishes the dispensary' do
      dispensary = create(:dispensary, user: user, status: :draft)
      post publish_api_v1_dispensary_path(dispensary)

      expect(response).to have_http_status(:ok)
      expect(dispensary.reload.status).to eq('published')
    end

    it 'denies publishing for non-owners' do
      other_dispensary = create(:dispensary, user: other_user, status: :draft)
      post publish_api_v1_dispensary_path(other_dispensary)

      expect(response).to have_http_status(:not_found) # set_owned_dispensary returns 404 for non-owned
      expect(other_dispensary.reload.status).to eq('draft')
    end
  end

  describe 'POST /api/v1/dispensaries/:id/unpublish' do
    it 'unpublishes the dispensary back to draft' do
      dispensary = create(:dispensary, user: user, status: :published)
      post unpublish_api_v1_dispensary_path(dispensary)

      expect(response).to have_http_status(:ok)
      expect(dispensary.reload.status).to eq('draft')
    end
  end
end
