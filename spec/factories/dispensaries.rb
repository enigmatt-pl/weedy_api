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
