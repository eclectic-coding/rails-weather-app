# Helper methods for tests that need a WeatherApiClient or WeatherApiService preconfigured for fast tests
module WeatherApiHelpers
  # Returns a WeatherApiClient configured to avoid retries and sleeps by default
  # Usage: client = build_test_client
  # You can pass `retry_options:` to override retry behavior for explicit retry tests.
  def build_test_client(base_url: nil, retry_options: nil, adapter: Faraday.default_adapter)
    base = base_url || (defined?(WeatherApiService) ? WeatherApiService::BASE_URL : nil)

    if retry_options
      WeatherApiClient.new(base_url: base, adapter: adapter, retry_options: retry_options)
    else
      WeatherApiClient.build_for_test(base_url: base, adapter: adapter)
    end
  end

  # Returns a WeatherApiService that uses a test client (no retries/sleeps by default)
  # Usage: service = build_test_service(api_key: 'abc')
  def build_test_service(api_key: 'test-key', base_url: nil, retry_options: nil)
    client = build_test_client(base_url: base_url, retry_options: retry_options)
    WeatherApiService.new(api_key: api_key, client: client)
  end
end

RSpec.configure do |config|
  config.include WeatherApiHelpers
end
