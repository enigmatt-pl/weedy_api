# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchResultsBuilder, type: :service do
  let(:user) { create(:user) }
  let!(:dispensary_warszawa) do
    create(:dispensary,
           title: 'Green Life',
           city: 'Warszawa',
           categories: %w[cbd hemp],
           status: :published,
           rating: 4.5)
  end
  let!(:dispensary_krakow) do
    create(:dispensary,
           title: 'Amber Herb',
           city: 'Kraków',
           categories: ['medical'],
           status: :published,
           rating: 4.8)
  end
  let!(:draft_dispensary) do
    create(:dispensary,
           title: 'Secret Garden',
           status: :draft)
  end

  describe '#fetch' do
    context 'without filters' do
      it 'returns all published dispensaries' do
        builder = described_class.new(params: {})
        result = builder.fetch

        expect(result[:results].size).to eq(2)
        expect(result[:results].pluck(:title)).not_to include('Secret Garden')
      end
    end

    context 'with text query' do
      it 'filters by title' do
        builder = described_class.new(params: { q: 'Green' })
        result = builder.fetch

        expect(result[:results].size).to eq(1)
        expect(result[:results].first[:title]).to eq('Green Life')
      end

      it 'is case-insensitive' do
        builder = described_class.new(params: { q: 'green' })
        result = builder.fetch
        expect(result[:results].first[:title]).to eq('Green Life')
      end
    end

    context 'with city filter' do
      it 'filters by city' do
        builder = described_class.new(params: { city: 'Kraków' })
        result = builder.fetch

        expect(result[:results].size).to eq(1)
        expect(result[:results].first[:city]).to eq('Kraków')
      end
    end

    context 'with category filter' do
      it 'filters by exact category using PostgreSQL unnest' do
        builder = described_class.new(params: { category: 'cbd' })
        result = builder.fetch

        expect(result[:results].size).to eq(1)
        expect(result[:results].first[:title]).to eq('Green Life')
      end

      it 'returns nothing for non-matching category' do
        builder = described_class.new(params: { category: 'accessories' })
        result = builder.fetch
        expect(result[:results]).to be_empty
      end
    end

    context 'ordering' do
      it 'orders by rating_desc' do
        builder = described_class.new(params: { order: 'rating_desc' })
        result = builder.fetch

        expect(result[:results].first[:title]).to eq('Amber Herb') # 4.8 vs 4.5
      end
    end

    context 'pagination' do
      it 'returns pagination metadata' do
        builder = described_class.new(params: { per_page: 1 })
        result = builder.fetch

        expect(result[:meta][:total_count]).to eq(2)
        expect(result[:meta][:total_pages]).to eq(2)
        expect(result[:meta][:current_page]).to eq(1)
      end
    end
  end
end
