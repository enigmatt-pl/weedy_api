require 'rails_helper'

RSpec.describe 'Api::V1::Admin::Users', type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let!(:user) { create(:user, :unapproved) }
  let(:headers) { { 'Authorization' => "Bearer #{JwtService.encode(super_admin.jwt_payload)}" } }

  describe 'GET /api/v1/admin/users' do
    it 'returns all users for super admin' do
      get api_v1_admin_users_path, headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'denies access to regular user' do
      user_headers = { 'Authorization' => "Bearer #{JwtService.encode(user.jwt_payload)}" }
      get api_v1_admin_users_path, headers: user_headers
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/v1/admin/users/:id/approve' do
    it 'approves a user' do
      post approve_api_v1_admin_user_path(user), headers: headers
      expect(response).to have_http_status(:ok)
      expect(user.reload.approved).to be true
    end

    it 'unapproves a user' do
      user.update(approved: true)
      post unapprove_api_v1_admin_user_path(user), headers: headers
      expect(response).to have_http_status(:ok)
      expect(user.reload.approved).to be false
    end
  end

  describe 'DELETE /api/v1/admin/users/:id' do
    it 'deletes a user' do
      delete api_v1_admin_user_path(user), headers: headers
      expect(response).to have_http_status(:no_content)
      expect(User.exists?(user.id)).to be false
    end
  end
end
