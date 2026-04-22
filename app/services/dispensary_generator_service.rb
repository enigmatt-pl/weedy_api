class DispensaryGeneratorService
  def initialize(query_data, images)
    @query_data = query_data
    @images = images
  end

  def call
    result = DispensaryService.new(@query_data, @images).call
    DispensaryParser.new(result[:raw_markdown].to_s, @query_data).parse
  rescue StandardError => e
    Rails.logger.error("DispensaryGeneratorService Failed: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    ErrorResult.build(e.message)
  end

  class ErrorResult
    def self.build(message)
      {
        reasoning: "Błąd generowania: #{message}",
        title: 'Błąd',
        description: '',
        estimated_price: '0',
        image_urls: []
      }.with_indifferent_access
    end
  end
end
