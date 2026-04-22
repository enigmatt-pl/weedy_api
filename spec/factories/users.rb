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
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    password { 'password123' }
    password_confirmation { 'password123' }
    accept_terms { true }
    accept_privacy { true }
    legal_version { 'v1-beta' }
    approved { true }
    role { :user }

    trait :super_admin do
      role { :super_admin }
    end

    trait :unapproved do
      approved { false }
    end
  end
end
