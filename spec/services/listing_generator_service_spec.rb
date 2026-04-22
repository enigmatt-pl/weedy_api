require 'rails_helper'

RSpec.describe ListingGeneratorService do
  let(:query_data) { 'Peugeot 307 Wspornik' }
  let(:images) { [] }
  let(:service) { described_class.new(query_data, images) }

  describe '#call' do
    let(:raw_markdown) do
      <<~MARKDOWN
        1. Identyfikacja części: Wspornik skrzyni automatycznej, Producent: Peugeot (OEM), OEM: 9680507080AA
        2. Ocena stanu: 7 - Bardzo dobry
        3. Analiza rynku i wycena:
        Znalezione ceny: [47.95 PLN, 42.00 PLN, 49.99 PLN, 72.00 PLN, 42.50 PLN] -> Odrzucono skrajne (42.00 PLN, 72.00 PLN) -> Mediana = 47.95 PLN. Stan oceniono na 7. Mnożnik = 120%. Obliczenia: 47.95 PLN * 120% = 57.54 PLN.
        4. Strategia cenowa:
        - Szybka sprzedaż: 48.91 PLN
        - Cena rynkowa: 57.54 PLN
        - Cena maksymalna: 66.17 PLN
        5. Tytuły aukcji:
        - WSPORNIK SKRZYNI PEUGEOT 307 9680507080AA
        - ŁAPA SKRZYNI PEUGEOT 307 9680507080AA
        - MOCOWANIE SKRZYNI PEUGEOT 307 9680507080AA
        6. Tagi wyszukiwania:
        wspornik, peugeot, 307, skrzynia
        7. Opis aukcji:
        WSPORNIK SKRZYNI AUTOMATYCZNEJ
        kod lakieru: brak

        MARKA: Peugeot
        MODEL: 307
        NUMER OEM: 9680507080AA

        STAN: Surowy stan faktyczny.
      MARKDOWN
    end

    before do
      allow_any_instance_of(PartListingService).to receive(:call).and_return({ raw_markdown: raw_markdown })
    end

    it 'extracts the decimal price correctly' do
      result = service.call
      expect(result[:estimated_price]).to eq(60)
    end

    it 'extracts the title correctly from section 5' do
      result = service.call
      expect(result[:title]).to eq('WSPORNIK SKRZYNI PEUGEOT 307 9680507080AA')
    end

    it 'extracts reasoning from sections 1-3' do
      result = service.call
      expect(result[:reasoning]).to include('Identyfikacja części')
      expect(result[:reasoning]).to include('Ocena stanu')
      expect(result[:reasoning]).to include('Analiza rynku')
      expect(result[:reasoning]).not_to include('4. Strategia cenowa')
    end

    context 'with integer price' do
      let(:raw_markdown) { "4. Strategia cenowa:\n- Cena rynkowa: 120 PLN" }

      it 'extracts it correctly' do
        result = service.call
        expect(result[:estimated_price]).to eq(120)
      end
    end

    context 'with thousand separator' do
      let(:raw_markdown) { "4. Strategia cenowa:\n- Cena rynkowa: 1 200,50 PLN" }

      it 'extracts and normalizes it' do
        result = service.call
        expect(result[:estimated_price]).to eq(1205)
      end
    end
  end
end
