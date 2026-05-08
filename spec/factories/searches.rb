# frozen_string_literal: true

FactoryBot.define do
  factory :search do
    query { 'CBD' }
    city { 'Warszawa' }
    results_count { 5 }
    ip_address { '127.0.0.1' }
    user_agent { 'TestAgent' }
  end
end
