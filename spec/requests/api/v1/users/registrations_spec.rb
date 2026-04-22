require 'rails_helper'

RSpec.describe 'Api::V1::Users::Registrations', type: :request do
  describe 'POST /api/v1/users' do
    let(:valid_attributes) do
      {
        user: {
          email: 'test@example.com',
          password: 'password123',
          password_confirmation: 'password123',
          first_name: 'John',
          last_name: 'Doe',
          accept_terms: true,
          accept_privacy: true,
          legal_version: 'v1-beta'
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new user and returns the user data with token' do
        expect do
          post api_v1_user_registration_path, params: valid_attributes
        end.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        json_response = response.parsed_body
        expect(json_response['token']).to be_present
        expect(json_response['user']['email']).to eq('test@example.com')
        expect(json_response['user']['first_name']).to eq('John')
        expect(json_response['user']['last_name']).to eq('Doe')
        expect(json_response['user']['avatar_url']).to be_nil
        expect(json_response['user']['allegro_configured']).to be(false)
        expect(json_response['user']['is_allegro_connected']).to be(false)
        expect(json_response['user']['olx_configured']).to be(false)
      end
    end

    describe 'PUT /api/v1/users' do
      let(:user) { create(:user, first_name: 'Old', last_name: 'Name') }
      let(:headers) { { 'Authorization' => "Bearer #{JwtService.encode(user_id: user.id)}" } }

      context 'with valid parameters' do
        it 'updates profile data and returns success' do
          put api_v1_user_registration_path,
              params: { user: { first_name: 'New', last_name: 'Name', city: 'Poznań' } },
              headers: headers

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json['user']['first_name']).to eq('New')
          expect(json['user']['city']).to eq('Poznań')
          expect(json['user']).to have_key('avatar_url')
          expect(user.reload.first_name).to eq('New')
        end
      end

      context 'when unauthenticated' do
        it 'returns 401' do
          put api_v1_user_registration_path, params: { user: { first_name: 'Fail' } }
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    describe 'PUT /api/v1/users/avatar' do
      let(:user) { create(:user) }
      let(:headers) { { 'Authorization' => "Bearer #{JwtService.encode(user_id: user.id)}" } }
      let(:file) { fixture_file_upload(Rails.root.join('spec/fixtures/files/dummy_image.jpg'), 'image/jpeg') }

      it 'uploads an avatar and returns the url' do
        put '/api/v1/users/avatar', params: { avatar: file }, headers: headers

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json['avatar_url']).to be_present
        expect(json['user']['avatar_url']).to eq(json['avatar_url'])
        expect(json['user']).to have_key('is_allegro_connected')
        expect(user.reload.avatar).to be_attached
      end
    end

    context 'with missing parameters' do
      it 'returns error if first_name or last_name is missing' do
        invalid_attributes = valid_attributes.deep_merge(user: { first_name: '' })
        post api_v1_user_registration_path, params: invalid_attributes

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['errors']).to include("First name can't be blank")
      end
    end
  end
end
