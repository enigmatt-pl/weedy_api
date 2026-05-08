# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Searches', type: :request do
  let(:user) { create(:user) }
  let!(:dispensary) { create(:dispensary, title: 'Test Dispensary', city: 'Warszawa', status: :published) }

  describe 'POST /api/v1/searches' do
    let(:valid_params) { { q: 'Test', city: 'Warszawa' } }

    it 'creates a search record and returns results' do
      post '/api/v1/searches', params: valid_params, as: :json

      expect(response).to have_http_status(:created)
      json = response.parsed_body

      expect(json['search_id']).to be_present
      expect(json['results']).to be_an(Array)
      expect(json['results'].first['title']).to eq('Test Dispensary')

      # Verify persistence
      expect(Search.count).to eq(1)
      expect(Search.last.query).to eq('Test')
    end
  end

  describe 'GET /api/v1/searches/:id' do
    let(:search_record) { create(:search, query: 'Test Query') }

    it 'returns existing search results' do
      get "/api/v1/searches/#{search_record.id}", as: :json

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['query']).to eq('Test Query')
      expect(json['results']).to be_an(Array)
    end

    it 'returns 404 for non-existent search' do
      get '/api/v1/searches/non-existent-id', as: :json
      expect(response).to have_http_status(:not_found)
    end
  end
end
