class DispensaryService
  def initialize(query_data, images)
    @query_data = query_data
    @images = images
  end

  def call
    # Keeping the fetcher call for now, though its logic might need future updates
    prices = MarketDataFetcher.new(@query_data, images: @images).fetch_raw_prices

    client = GeminiMegaPromptClient.new
    raw_response = client.generate(compiled_prompt(prices), @images)

    { raw_markdown: raw_response }
  end

  private

  def images_present?
    @images.present?
  end

  def compiled_prompt(prices)
    live_prices_json = prices.present? ? prices.to_json : "[]"

    <<~PROMPT
      Jesteś systemem eksperckim do analizy i tworzenia profesjonalnych profili dla placówek typu "Dispensary" (punktów sprzedaży i konsultacji). 
      Operujesz na faktach, twardych danych i estetyce. Twoim celem jest przygotowanie kompletnego wpisu do bazy danych Weedy.

      DANE WEJŚCIOWE:
      #{@query_data}

      ### 1. ANALIZA LOKALIZACJI I TOŻSAMOŚCI
      Na podstawie DANYCH WEJŚCIOWYCH (Nazwa, Adres, Lokalizacja) ustal:
      - Dokładną tożsamość punktu.
      - Otoczenie rynkowe (czy to prestiżowa lokalizacja, punkt osiedlowy, czy centrum medyczne).
      - Styl placówki (Modern, Organic, Medical, Boutique).

      ### 2. SCORING WIZUALNY I ANALIZA ZDJĘĆ
      Jeśli dostarczono zdjęcia, przeanalizuj:
      - Wystrój wnętrza (czystość, profesjonalizm, oświetlenie).
      - Ekspozycję produktów.
      - Dostępność (wejście, udogodnienia).
      Scoring (1–10):
      10 – Standard premium, butikowy wystrój.
      7–8 – Bardzo dobry, profesjonalny wygląd medyczny/biurowy.
      5–6 – Poprawny, standardowy punkt handlowy.
      1–4 – Wymaga poprawy estetycznej lub remontu.

      ### 3. JAWNA MATEMATYKA (POTENCJAŁ RYNKOWY)
      Sekcja 3 MUSI zawierać dowód analizy potencjału:
      "Lokalizacja -> Estymowany ruch -> Scoring Wizualny -> Potencjał Rynkowy = X/100. Unikalne cechy: [Cechy]."

      ### 4. ZASADY KRYTYCZNE
      1. ZAKAZ używania terminologii "MotoWrzutka" lub części samochodowych.
      2. ZAKAZ słów "Brak", "Nieokreślony". Jeśli brak danych → POMIŃ całą linię.
      3. TYTUŁ MAX 75 ZNAKÓW: Musi zawierać nazwę i miasto/dzielnicę.
      4. OPIS: Profesjonalny język, skupienie na jakości obsługi i asortymencie.

      ### 5. STRUKTURA WYJŚCIOWA (STRICT SCHEMA)
      Odpowiadaj WYŁĄCZNIE w poniższej strukturze. Żadnych powitań.

      1. Identyfikacja: [Nazwa, Adres, Miasto, Typ placówki, Status]
      2. Ocena stanu: [Wynik 1-10] - [Uzasadnienie na podstawie zdjęć i danych]
      3. Analiza rynkowa:
      [JAWNA MATEMATYKA POTENCJAŁU]
      FINAL_VALUATION: [POTENCJAŁ 1-100]
      4. Strategia:
      [Główne wyróżniki rynkowe placówki]
      5. Tytuły (MAX 75 ZN) - WERSALIKI:
      - [NAZWA DISPENSARY] [MIASTO/DZIELNICA] - PROFESJONALNA OBSŁUGA
      - [Wersja alternatywna z akcentem na lokalizację]
      6. Tagi: [10–15 tagów: nazwa, miasto, branża, udogodnienia]
      7. Opis:
      [SZCZEGÓŁOWY OPIS PLACÓWKI WERSALIKAMI TYTUŁ]
      [Misja i opis asortymentu]
      [Szczegóły lokalizacji i dostępności]
      [Godziny otwarcia i udogodnienia - jeśli wykryte]

      STAN: Część bazy Weedy. Zweryfikowany profil placówki.
    PROMPT
  end
end
