require 'rails_helper'

RSpec.describe 'Api::V1::AllegroIntegration', type: :request do
  let(:user) { create(:user) }
  let(:headers) { { 'Authorization' => "Bearer #{JwtService.encode(user_id: user.id)}" } }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('ALLEGRO_CLIENT_ID', nil).and_return('test_id')
    allow(ENV).to receive(:fetch).with('ALLEGRO_CLIENT_SECRET', nil).and_return('test_secret')
    allow(ENV).to receive(:fetch).with('ALLEGRO_REDIRECT_URI', anything).and_return('http://test.com/callback')
  end

  describe 'GET /api/v1/allegro_integration/auth_url' do
    it 'returns the authorize URL' do
      get '/api/v1/allegro_integration/auth_url', headers: headers

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['url']).to include('/auth/oauth/authorize')
      expect(json['url']).to include('client_id=test_id')
    end

    context 'with individual user credentials' do
      before do
        create(:allegro_integration, user: user, client_id: 'user_specific_id', client_secret: 'user_secret')
      end

      it 'uses user-specific client_id' do
        get '/api/v1/allegro_integration/auth_url', headers: headers
        expect(response.parsed_body['url']).to include('client_id=user_specific_id')
      end
    end
  end

  describe 'POST /api/v1/allegro_integration/callback' do
    context 'when successful' do
      before do
        stub_request(:post, %r{https://allegro\.pl.*/auth/oauth/token})
          .with(body: /grant_type=authorization_code/)
          .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: {
            access_token: 'abc',
            refresh_token: 'def',
            expires_in: 3600
          }.to_json)
      end

      it 'exchanges code for tokens and saves them' do
        post '/api/v1/allegro_integration/callback', params: { code: 'valid_code' }.to_json, headers: headers.merge('CONTENT_TYPE' => 'application/json')

        expect(response).to have_http_status(:ok)
        expect(user.allegro_integration.reload.access_token).to eq('abc')
      end
    end

    context 'when exchange fails' do
      before do
        stub_request(:post, %r{https://allegro\.pl.*/auth/oauth/token})
          .to_return(status: 400, body: 'Invalid code')
      end

      it 'returns unprocesable content' do
        post '/api/v1/allegro_integration/callback', params: { code: 'bad' }.to_json, headers: headers.merge('CONTENT_TYPE' => 'application/json')
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'GET /api/v1/allegro_integration/status' do
    it 'returns disconnected initially' do
      get '/api/v1/allegro_integration/status', headers: headers
      expect(response.parsed_body['connected']).to be false
    end

    it 'returns connected after integration' do
      create(:allegro_integration, user: user)
      get '/api/v1/allegro_integration/status', headers: headers
      expect(response.parsed_body['connected']).to be true
    end
  end
end
