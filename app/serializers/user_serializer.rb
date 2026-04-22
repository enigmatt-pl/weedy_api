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
class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :first_name, :last_name, :role, :approved, :credits, :city, :postcode, :province,
             :created_at, :avatar_url_static

  delegate :avatar_url_static, to: :object
end
