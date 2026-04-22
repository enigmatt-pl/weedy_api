require 'rails_helper'

RSpec.describe 'Api::V1::AllegroAuths', type: :request do
  let(:user) { create(:user) }
  let(:headers) { { 'Authorization' => "Bearer #{JwtService.encode(user_id: user.id)}" } }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('ALLEGRO_CLIENT_ID').and_return('test_id')
    allow(ENV).to receive(:fetch).with('ALLEGRO_CLIENT_SECRET').and_return('test_secret')
    allow(ENV).to receive(:fetch).with('ALLEGRO_REDIRECT_URI').and_return('http://test.com/callback')
    allow(ENV).to receive(:fetch).with('ALLEGRO_ENV', 'sandbox').and_return('sandbox')
    allow(ENV).to receive(:fetch).with('FRONTEND_URL', anything).and_return('http://localhost:5173')
  end

  describe 'GET /api/v1/allegro/auth' do
    it 'returns the authorize URL' do
      get '/api/v1/allegro/auth', headers: headers

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['url']).to include('allegro.pl.allegrosandbox.pl/auth/oauth/authorize')
      expect(json['url']).to include('client_id=')
      expect(json['url']).to include('response_type=code')

      expect(user.reload.allegro_auth_state).not_to be_nil
    end
  end

  describe 'GET /api/v1/allegro/callback' do
    let(:state) { 'random_state' }

    before do
      user.update!(allegro_auth_state: state)
    end

    context 'when successful' do
      before do
        stub_request(:post, %r{auth/oauth/token})
          .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: {
            access_token: 'abc',
            refresh_token: 'def',
            expires_in: 3600
          }.to_json)
      end

      it 'exchanges code for tokens and redirects to dashboard' do
        get '/api/v1/allegro/callback', params: { code: 'valid_code', state: state }

        expect(response).to redirect_to('http://localhost:5173/dashboard?allegro=connected')

        user.reload
        expect(user.allegro_integration.reload.access_token).to eq('abc')
        expect(user.allegro_integration.refresh_token).to eq('def')
        expect(user.allegro_auth_state).to be_nil
      end
    end

    context 'when code is missing' do
      it 'redirects to settings with error' do
        get '/api/v1/allegro/callback', params: { state: state }
        expect(response).to redirect_to('http://localhost:5173/settings?error=allegro_auth_failed')
      end
    end

    context 'when state is invalid' do
      it 'redirects to settings with error' do
        get '/api/v1/allegro/callback', params: { code: 'code', state: 'wrong' }
        expect(response).to redirect_to('http://localhost:5173/settings?error=user_not_found')
      end
    end
  end
end
