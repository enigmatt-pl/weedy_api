require 'net/http'
require 'json'
require 'uri'

class MarketDataFetcher
  def initialize(query_params, images: [], api_key: ENV['SERP_API_KEY'])
    @query_params = query_params
    @images = images
    @api_key = api_key
  end

  def fetch_raw_prices
    Rails.logger.info "[MarketDataFetcher] 🚀 STARTING Tiered Data Harvest for query: #{@query_params.inspect}"

    # 0. Tier 0: Native Allegro API (Clean, Free, Fast)
    allegro_native = Allegro::MarketInsightService.new(clean_query).call
    Rails.logger.info "[MarketDataFetcher] -> Allegro Native API found #{allegro_native.size} items."

    # 1. SHORT-CIRCUIT: Jeśli mamy wystarczająco dużo czystych danych z Allegro API, od razu uciekamy do AI (Oszczędność SerpApi)
    if allegro_native.size >= 10
      Rails.logger.info "[MarketDataFetcher] ⚡ SHORT-CIRCUIT: Sufficient native Allegro data found. Skipping supplemental SerpApi search."
      return extract_prices_with_ai(allegro_native)
    end

    # 2. Pobieramy dane z SerpApi (Supplemental Data: OLX, Otomoto, eBay, Global)
    if @api_key.blank?
      Rails.logger.warn "[MarketDataFetcher] ⚠️ Skipping SerpApi supplemental harvest (API_KEY missing)."
      return extract_prices_with_ai(allegro_native)
    end

    Rails.logger.info "[MarketDataFetcher] 🔍 Supplemental Harvest for: OLX, Otomoto, eBay & Global..."
    organic_data  = fetch_serp(organic_params)
    shopping_data = fetch_serp(shopping_params)
    global_data   = fetch_serp(global_params)

    Rails.logger.info "[MarketDataFetcher] ✅ SerpApi Returns -> Organic: #{organic_data.dig('organic_results')&.size.to_i}, Shopping: #{shopping_data.dig('shopping_results')&.size.to_i}, Global: #{global_data.dig('organic_results')&.size.to_i}"

    # 3. Budujemy listę kandydatów (Native + SerpApi)
    candidates = build_candidates(organic_data, shopping_data, global_data, allegro_native)

    if candidates.empty?
      Rails.logger.warn "[MarketDataFetcher] ⚠️ No candidates found across all 3 search sources."
      return []
    end

    Rails.logger.info "[MarketDataFetcher] 🔍 Built candidate pool. Size: #{candidates.size} items."

    # 3. Warstwa AI (Layer 1)
    extracted_prices = extract_prices_with_ai(candidates)
    
    # Dodajemy logowanie by widzieć co AI odrzuciło
    if extracted_prices.empty? && candidates.any? { |c| c[:price].present? }
      Rails.logger.warn "[MarketDataFetcher] 🚨 WARNING: AI rejected ALL candidates! Included candidates with prices that were dropped: #{candidates.select{|c| c[:price].present?}.to_json}"
    end

    Rails.logger.info "[MarketDataFetcher] 🎯 FINAL AI Extracted Prices (N=#{extracted_prices.size}): #{extracted_prices.inspect}"
    extracted_prices
  rescue StandardError => e
    Rails.logger.error("[MarketDataFetcher] ❌ FATAL Error: #{e.message}\n#{e.backtrace.first(3).join("\n")}")
    []
  end

  private

  def fetch_serp(params)
    uri = URI('https://serpapi.com/search')
    uri.query = URI.encode_www_form(params)
    response = Net::HTTP.get_response(uri)
    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.error("SerpApi fetch failed: #{e.message}")
    {}
  end

  def clean_query
    input = @query_params.to_s.strip
    input.gsub(/[\r\n]+/, ' ').squeeze(' ')
  end

  def is_pure_oem?
    # If the query contains no lowercase letters, it's considered a pure OEM query 
    # (e.g. "1X4E19N586AB" or "(1X4315K609AD OR 510070120)").
    !clean_query.match?(/[a-z]/)
  end

  def broad_query(limit: 5)
    # Usuwamy roczniki, kody (X400) i zbędne detereminanty
    query = clean_query.gsub(/\b\d{2,4}-\d{2,4}\b/, '') # Usuń 2001-2007
                       .gsub(/\b\d{2,4}\b/, '')     # Usuń pojedyncze lata
                       .gsub(/\b[A-Z]\d{3}\b/i, '') # Usuń X400 itp
                       .gsub(/\b(?:używana|tylna|tył)\b/i, '')
    
    words = query.split(/\s+/).reject(&:blank?)
    # Bierzemy max 5 słów - to powinno wystarczyć (Część + Marka + Model)
    words.take(limit).join(' ')
  end

  # Google Shopping - BEZ site: filtrów (szukamy wszędzie)
  def shopping_params
    {
      # Zawsze wymuszamy 'używana', aby nie pobierać cen nowych części OEM z ASO
      q: "#{broad_query(limit: 4)} używana",
      engine: 'google_shopping',
      hl: 'pl',
      gl: 'pl',
      api_key: @api_key
    }
  end

  # Search Global - bez site: filtrów, by złapać mniejsze sklepy z cenami w snippetach
  def global_params
    {
      # Zawsze wymuszamy 'używana', by nie łapać nowych części z hurtowni i dropshipperów (np. motoallegro)
      q: "#{clean_query} używana cena",
      engine: 'google',
      hl: 'pl',
      gl: 'pl',
      api_key: @api_key
    }
  end

  def organic_params
    # Skupiamy SerpApi na OLX i Otomoto, bo Allegro mamy już z natywnego API (Tier 0).
    # To oszczędza miejsce w zapytaniu i zwiększa precyzję dla pozostałych portali.
    q = "(site:olx.pl OR site:otomoto.pl OR site:ebay.pl) #{clean_query}"
    q += " używana" unless is_pure_oem?
    
    {
      q: q,
      engine: 'google',
      hl: 'pl',
      gl: 'pl',
      api_key: @api_key
    }
  end

  def build_candidates(organic, shopping, global, native = [])
    candidates = native # Start with native Allegro results

    # Dodaj wyniki z Google Shopping
    [shopping['shopping_results'], shopping['inline_shopping_results']].each do |results|
      next unless results.is_a?(Array)
      results.each do |item|
        candidates << {
          title: item['title'],
          price: item['price'] || item['extracted_price'],
          source: item['source'] || 'Google Shopping'
        }
      end
    end

    # Dodaj wyniki organiczne (snippety i karuzele)
    # Dodaj wyniki globalne (snippety i karuzele)
    [global['organic_results'], organic['organic_results']].each do |results|
      next unless results.is_a?(Array)
      results.each do |item|
        title = item['title'].to_s
        snippet = item['snippet'].to_s

        # Szukamy ceny w polach strukturalnych
        price = item['price'] || item['extracted_price'] || 
                item.dig('rich_snippet', 'top', 'detected_extensions', 'price') ||
                item.dig('rich_snippet', 'top', 'extensions')&.find { |e| e.match?(/[0-9]+\s*(zł|PLN)/i) }

        # Jeśli brak - spróbuj wyciągnąć prostym regexem z tytułu/snippetu jako fallback do analizy dla AI
        if price.blank?
          if (m = "#{title} #{snippet}".match(/([0-9][0-9\s,.]*)[\s]*(?:zł|PLN|zl)/i))
            price = m[1].gsub(/\s/, '').gsub(',', '.')
          end
        end

        candidates << {
          title: title,
          snippet: snippet,
          price: price,
          source: item['source'] || item['link']
        }

        # Karuzela produktów (często zawiera konkretne oferty)
        item['carousel']&.each do |c|
          candidates << {
            title: c['title'],
            source: c['link']
          }
        end
      end
    end

    candidates.uniq { |c| [c[:title], c[:price]] } # Uniq by title (compact removed to allow AI to see price-less items for context)
  end

  def extract_prices_with_ai(candidates)
    prompt = <<~PROMPT
      Jesteś parserem cen dla części samochodowych. Szukamy cen dla: "#{@query_params}".
      Masz dostęp do zdjęć szukanej części. Twoim zadaniem jest znalezienie ofert pasujących do tej FIZYCZNEJ części.
      
      DANE DO ANALIZY:
      #{candidates.to_json}

      ZASADY:
      1. Znajdź pozycje pasujące do zapytania. BĄDŹ BARDZO SUROWY DLA TYPU CZĘŚCI: Najpierw zidentyfikuj fizyczny przedmiot na załączonych zdjęciach. Oferty muszą precyzyjnie celować w TĘ SAMĄ CZĘŚĆ, a nie cały moduł, do którego jest przymocowana (np. jeśli na zdjęciu to tylko mały 'czujnik', a oferta to cała 'lampa kabiny i podsufitka' czy 'światło fotela' z tym czujnikiem, ODRZUĆ JĄ bezwzględnie jako fałszywy szum!).
      2. Wyciągnij cenę (PLN). Cena może być w polu "price", ale może też być ukryta w "title" lub "snippet" (np. "299 zł", "150zł", "kup za 99").
      3. Zwróć tablicę JSON: [{"cena": float, "zrodlo": string, "tytul": string}]
      4. POMIŃ wyniki, dla których w ogóle nie da się określić ceny.
      
      Zwróć WYŁĄCZNIE tablicę JSON.
    PROMPT


    client = GeminiMegaPromptClient.new
    ai_response = client.generate(prompt, @images)

    # Oczyszczanie JSONa z tagów markdown i białych znaków
    clean_json = ai_response.to_s
                             .gsub(/```(?:json)?/i, '')
                             .gsub(/```/, '')
                             .strip
    
    begin
      parsed = JSON.parse(clean_json)
      return [] unless parsed.is_a?(Array)

      # Zwracamy listę floatów do dalszej obróbki w PartListingService
      prices = parsed.map { |item| (item['cena'] || item['price']).to_f }.select { |p| p >= 10 }
      
      Rails.logger.debug "MarketDataFetcher: AI extracted prices: #{prices.inspect}"
      prices
    rescue JSON::ParserError => e
      Rails.logger.error("MarketDataFetcher AI JSON Error: #{e.message}")
      []
    end
  end
end
