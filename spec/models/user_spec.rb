# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  accepted_privacy_at    :datetime
#  accepted_terms_at      :datetime
#  allegro_auth_state     :string
#  approved               :boolean          default(FALSE)
#  avatar_url             :string
#  city                   :string
#  credits                :integer          default(0), not null
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  first_name             :string
#  last_name              :string
#  legal_version          :string
#  postcode               :string
#  province               :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :integer          default("user")
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'RBAC & Approval' do
    it 'defaults to user role' do
      user = build(:user)
      expect(user.role).to eq('user')
    end

    it 'is not active if not approved' do
      user = build(:user, approved: false)
      expect(user.active_for_authentication?).to be false
      expect(user.inactive_message).to eq(:not_approved)
    end
  end

  describe 'Legal Consents' do
    it 'sets timestamps on creation via virtual attributes' do
      user = create(:user, accept_terms: true, accept_privacy: true)
      expect(user.accepted_terms_at).to be_present
      expect(user.accepted_privacy_at).to be_present
    end

    it 'is not active if timestamps missing' do
      user = create(:user)
      user.update_columns(accepted_terms_at: nil)
      expect(user.reload.active_for_authentication?).to be false
      expect(user.inactive_message).to eq(:terms_not_accepted)
    end
  end

  describe '#jwt_payload' do
    it 'contains role and approval state' do
      user = create(:user, :super_admin)
      payload = user.jwt_payload
      expect(payload[:role]).to eq('super_admin')
      expect(payload[:approved]).to be true
      expect(payload[:user_id]).to eq(user.id)
    end
  end
end
