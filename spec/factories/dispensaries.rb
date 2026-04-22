# == Schema Information
#
# Table name: dispensaries
#
#  id                  :uuid             not null, primary key
#  categories          :text             default([]), is an Array
#  city                :string
#  description         :text
#  email               :string
#  estimated_price     :decimal(10, 2)   default(0.0), not null
#  hours               :text
#  image_urls          :jsonb
#  latitude            :decimal(10, 6)
#  longitude           :decimal(10, 6)
#  market_data         :jsonb
#  phone               :string
#  query_data          :text
#  rating              :decimal(3, 2)    default(0.0)
#  reasoning           :text
#  status              :integer          default("draft"), not null
#  title               :string           not null
#  website             :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  category_id         :string
#  external_product_id :string
#  platform_product_id :string
#  user_id             :uuid             not null
#  verification_id     :string
#
# Indexes
#
#  index_dispensaries_on_categories       (categories) USING gin
#  index_dispensaries_on_city             (city)
#  index_dispensaries_on_created_at       (created_at)
#  index_dispensaries_on_status           (status)
#  index_dispensaries_on_user_id          (user_id)
#  index_dispensaries_on_verification_id  (verification_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :dispensary do
    user
    verification_id { Faker::Number.number(digits: 10).to_s }
    title { Faker::Company.name + " Dispensary" }
    description { Faker::Lorem.paragraph(sentence_count: 3) }
    estimated_price { Faker::Commerce.price(range: 50.0..500.0) }
    status { :draft }

    trait :generating do
      status { :generating }
      title { '[GENERATING...]' }
      description { '[AI is processing...]' }
      estimated_price { 0.0 }
    end
  end
end
