require 'rails_helper'

RSpec.describe "Weather page", type: :request do
  describe "GET /weather" do
    it "renders the search form" do
      get weather_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Weather Search')
      expect(response.body).to include('ZIP code')
      expect(response.body).to include('City / State')
    end

    it "shows weather results when searching by zip (service success)" do
      service = build_test_service(api_key: 'test-key')
      result_hash = {
        name: 'Testville',
        sys: { country: 'US' },
        main: { temp: 72.5, humidity: 50 },
        weather: [{ description: 'clear sky' }],
        wind: { speed: 5.1 }
      }

      allow(service).to receive(:fetch_by_zip).with('02139').and_return(result_hash)
      allow(WeatherApiService).to receive(:new).and_return(service)

      get weather_path, params: { zip: '02139' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Weather for Testville')
      expect(response.body).to include('Temperature')
      expect(response.body).to include('72.5')
      expect(response.body).to match(/clear sky/i)
    end

    it "shows API error when service returns error" do
      service = build_test_service(api_key: 'test-key')
      err = { error: 'API request failed (401): Invalid API key' }

      allow(service).to receive(:fetch_by_zip).with('99999').and_return(err)
      allow(WeatherApiService).to receive(:new).and_return(service)

      get weather_path, params: { zip: '99999' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('API error:')
      expect(response.body).to include('Invalid API key')
    end

    it "validates ZIP format and shows a validation error" do
      get weather_path, params: { zip: '123' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('ZIP code must be 5 digits')
    end

    it "searches by city and state and shows results" do
      service = build_test_service(api_key: 'test-key')
      result_hash = {
        name: 'Cityville',
        sys: { country: 'US' },
        main: { temp: 60 }
      }

      allow(service).to receive(:fetch_by_city_and_state).with('Cityville', 'MA').and_return(result_hash)
      allow(WeatherApiService).to receive(:new).and_return(service)

      get weather_path, params: { city: 'Cityville', state: 'MA' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Weather for Cityville')
      expect(response.body).to include('60')
    end
  end
end
