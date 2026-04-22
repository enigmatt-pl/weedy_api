require 'rails_helper'

RSpec.describe 'Api::V1::Users::Sessions', type: :request do
  describe 'POST /api/v1/users/sign_in' do
    let!(:user) { create(:user, email: 'login@example.com', password: 'password123', first_name: 'Jane', last_name: 'Smith') }
    let(:valid_login_params) do
      {
        user: {
          email: 'login@example.com',
          password: 'password123'
        }
      }
    end

    context 'with valid credentials' do
      it 'logs in the user and returns the user data with names' do
        post api_v1_user_session_path, params: valid_login_params

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body
        expect(json_response['token']).to be_present
        expect(json_response['user']['first_name']).to eq('Jane')
        expect(json_response['user']['last_name']).to eq('Smith')
        expect(json_response['user']).to have_key('avatar_url')
        expect(json_response['user']['allegro_configured']).to be(false)
        expect(json_response['user']['is_allegro_connected']).to be(false)
        expect(json_response['user']['olx_configured']).to be(false)
      end
    end

    context 'with invalid credentials' do
      it 'returns unauthorized error' do
        post api_v1_user_session_path, params: { user: { email: 'login@example.com', password: 'wrong' } }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
