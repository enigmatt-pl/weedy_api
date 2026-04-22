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
class AllegroIntegration < ApplicationRecord
  belongs_to :user

  encrypts :access_token, :refresh_token, :client_secret

  validates :access_token, :refresh_token, :expires_at, :client_id, :client_secret, presence: true

  def expired?
    expires_at.past?
  end
end
