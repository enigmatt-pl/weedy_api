# frozen_string_literal: true

class CreateSearches < ActiveRecord::Migration[7.1]
  def change
    create_table :searches, id: :uuid, default: -> { 'gen_random_uuid()' } do |t|
      t.string :query
      t.string :city
      t.string :category
      t.string :order, default: 'relevance'
      t.jsonb :filters, default: {}
      t.integer :results_count, default: 0
      t.string :ip_address
      t.string :user_agent
      t.references :user, type: :uuid, null: true, foreign_key: true, index: true

      t.timestamps
    end

    add_index :searches, :created_at
    add_index :searches, :query
    add_index :searches, :city
  end
end
