class DispensaryWorker
  include Sidekiq::Worker

  def perform(dispensary_id)
    dispensary = Dispensary.find(dispensary_id)

    query_data = dispensary.query_data.presence || dispensary.verification_id
    images = dispensary.images.map { |img| img }

    generator = DispensaryGeneratorService.new(query_data, images)
    generated_data = generator.call

    dispensary.update!(
      title: generated_data[:title],
      description: generated_data[:description],
      estimated_price: generated_data[:estimated_price],
      reasoning: generated_data[:reasoning],
      status: :draft
    )
  rescue StandardError => e
    Rails.logger.error("DispensaryWorker failed for Dispensary ID: #{dispensary_id}. Error: #{e.message}")
    dispensary&.update(status: :failed)
  end
end
