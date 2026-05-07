# frozen_string_literal: true

# == Schema Information
#
# Table name: searches
#
#  id            :uuid             not null, primary key
#  category      :string
#  city          :string
#  filters       :jsonb
#  ip_address    :string
#  order         :string           default("relevance")
#  query         :string
#  results_count :integer          default(0)
#  user_agent    :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :uuid
#
# Indexes
#
#  index_searches_on_city        (city)
#  index_searches_on_created_at  (created_at)
#  index_searches_on_query       (query)
#  index_searches_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Search < ApplicationRecord
  belongs_to :user, optional: true

  validates :results_count, numericality: { greater_than_or_equal_to: 0 }

  scope :recent, -> { order(created_at: :desc) }
  scope :with_query, -> { where.not(query: [nil, '']) }
  scope :by_city, ->(city) { where(city: city) }
end
