# frozen_string_literal: true

class Search < ApplicationRecord
  belongs_to :user, optional: true

  validates :results_count, numericality: { greater_than_or_equal_to: 0 }

  scope :recent, -> { order(created_at: :desc) }
  scope :with_query, -> { where.not(query: [nil, '']) }
  scope :by_city, ->(city) { where(city: city) }
end
