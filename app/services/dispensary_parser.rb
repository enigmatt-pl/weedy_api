class DispensaryParser
  def initialize(markdown, query_data)
    @markdown = markdown.to_s
    @query_data = query_data
    @sections = extract_sections
  end

  def parse
    {
      reasoning: parse_reasoning,
      title: parse_title,
      description: parse_description,
      estimated_price: parse_price,
      image_urls: []
    }.with_indifferent_access
  end

  private

  def extract_sections
    @markdown.split(/(?=^\d{1,2}\.\s+)/m).map(&:strip).reject(&:empty?)
  end

  def section(number)
    @sections.find { |s| s.match?(/\A#{number}\.\s+/i) } || ''
  end

  def parse_reasoning
    [section(1), section(2), section(3)]
      .reject(&:empty?)
      .join("\n\n")
      .gsub(/\*+/, '')
      .strip
  end

  def parse_price
    price_match = @markdown.match(/(?:FINAL_VALUATION|Rynkowa):\s*\*?\*?\s*(\d+[\d\s]*[.,]?\d*)/i)
    return '0' unless price_match

    raw_price = price_match[1].gsub(/\s/, '').tr(',', '.').to_f
    (raw_price / 5.0).ceil * 5
  end

  def parse_title
    lines = section(5).lines
    candidate = lines.find { |l| l.match?(/^\s*[-*]\s+\S/) }

    return fallback_title unless candidate

    candidate.sub(/^\s*[-*]\s+/, '')
             .sub(/^\[.*?\]\s*/i, '')
             .sub(/^(?:Wariant|Opcja|Wersja)\s+\d+:?\s*/i, '')
             .strip.gsub(/["#*]/, '')[0..74]
  end

  def parse_description
    content = section(7)
    first_line = content.lines.first || ''
    
    if first_line.match?(/\b7\.\s+Opis/i)
      content.sub(first_line, '').strip.gsub(/\*+/, '').strip
    else
      content.gsub(/\*+/, '').strip
    end
  end

  def fallback_title
    match = section(1).match(/(?:Nazwa|Identyfikacja):\s*([^,\n\r*]+)/i)
    type = match ? match[1].strip : @query_data.to_s
    type[0..74]
  end
end
