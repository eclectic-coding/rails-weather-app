require 'rails_helper'

RSpec.describe WeatherApiService, type: :service do
  let(:api_key) { 'test-key' }
  let(:client) { build_test_client(base_url: WeatherApiService::BASE_URL) }
  let(:service) { described_class.new(api_key: api_key, client: client) }

  describe '#fetch_by_zip' do
    it 'returns parsed JSON on success' do
      body = {
        name: 'Testville',
        sys: { country: 'US' },
        main: { temp: 72.5, humidity: 50 },
        weather: [{ description: 'clear sky' }],
        wind: { speed: 5.1 }
      }.to_json

      allow(client).to receive(:get).and_return(OpenStruct.new(status: 200, body: body, reason_phrase: 'OK'))

      result = service.fetch_by_zip('02139')
      expect(result).to be_a(Hash)
      expect(result[:name]).to eq('Testville')
      expect(result.dig(:main, :temp)).to eq(72.5)
      expect(result.dig(:weather, 0, :description)).to eq('clear sky')
    end

    it 'returns an error hash when API returns non-200' do
      body = { message: 'Invalid API key' }.to_json
      allow(client).to receive(:get).and_return(OpenStruct.new(status: 401, body: body, reason_phrase: 'Unauthorized'))

      result = service.fetch_by_zip('99999')
      expect(result).to be_a(Hash)
      expect(result[:error]).to match(/API request failed/)
    end

    it 'returns an error hash when response is invalid JSON' do
      allow(client).to receive(:get).and_return(OpenStruct.new(status: 200, body: 'not-json', reason_phrase: 'OK'))

      result = service.fetch_by_zip('00000')
      expect(result).to be_a(Hash)
      expect(result[:error]).to match(/Invalid JSON response/)
    end

    it 'returns an error hash when network times out' do
      allow(client).to receive(:get).and_raise(Faraday::TimeoutError.new('execution expired'))

      result = service.fetch_by_zip('88888')
      expect(result).to be_a(Hash)
      expect(result[:error]).to be_a(String)
      expect(result[:error].strip).not_to be_empty
    end

    it 'returns an error hash when connection is refused' do
      allow(client).to receive(:get).and_raise(Faraday::ConnectionFailed.new('connection refused'))

      result = service.fetch_by_zip('77777')
      expect(result).to be_a(Hash)
      expect(result[:error]).to be_a(String)
      expect(result[:error].strip).not_to be_empty
    end
  end

  describe '#fetch_by_city_and_state' do
    it 'builds the correct query and parses the response' do
      body = { name: 'Cityville', sys: { country: 'US' }, main: { temp: 60 } }.to_json

      allow(client).to receive(:get).and_return(OpenStruct.new(status: 200, body: body, reason_phrase: 'OK'))

      result = service.fetch_by_city_and_state('Cityville', 'MA')
      expect(result[:name]).to eq('Cityville')
      expect(result.dig(:main, :temp)).to eq(60)
    end
  end
end
