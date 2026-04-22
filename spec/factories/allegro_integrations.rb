# == Schema Information
#
# Table name: allegro_integrations
#
#  id            :uuid             not null, primary key
#  access_token  :text
#  auth_state    :string
#  client_secret :text
#  expires_at    :datetime
#  refresh_token :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  client_id     :string
#  user_id       :uuid             not null
#
# Indexes
#
#  index_allegro_integrations_on_user_id  (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :allegro_integration do
    user
    access_token { 'valid_token' }
    refresh_token { 'refresh_token' }
    expires_at { 1.hour.from_now }
    client_id { 'test_client_id' }
    client_secret { 'test_client_secret' }
  end
end
