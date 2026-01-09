require 'uri'
require 'json'
require_relative 'weather_api_client'

class WeatherApiService
  BASE_URL = "https://api.openweathermap.org/data/2.5/weather".freeze

  def initialize(api_key: nil, client: nil)
    cred_key = defined?(Rails) && Rails.respond_to?(:application) ? Rails.application.credentials[:weather_api_key] : nil
    @api_key = api_key || cred_key || ENV['OPENWEATHER_API_KEY'] || ENV['OPENWEATHERMAP_API_KEY']

    if @api_key.nil? || @api_key.to_s.strip.empty?
      raise ArgumentError, "OpenWeather API key not configured. Set credentials.weather_api_key or ENV['OPENWEATHER_API_KEY']"
    end

    @client = client || WeatherApiClient.new(base_url: BASE_URL)
  end

  def fetch_by_zip(zip, country: 'us')
    query = { zip: "#{zip},#{country}", appid: @api_key, units: 'imperial' }
    request(query)
  end

  def fetch_by_city_and_state(city, state, country: 'us')
    q = "#{city},#{state},#{country}"
    query = { q: q, appid: @api_key, units: 'imperial' }
    request(query)
  end

  def fetch_by_coords(lat, lon)
    query = { lat: lat, lon: lon, appid: @api_key, units: 'imperial' }
    request(query)
  end

  private

  def request(query)
    begin
      res = @client.get(query)

      status = res.status
      body = res.body

      if status >= 200 && status < 300
        begin
          JSON.parse(body, symbolize_names: true)
        rescue JSON::ParserError => e
          { error: "Invalid JSON response: #{String(e)}" }
        end
      else
        parsed = begin
          JSON.parse(body, symbolize_names: true) rescue nil
        end
        message = parsed && parsed[:message] ? parsed[:message] : res.reason_phrase
        { error: "API request failed (#{status}): #{message}", raw_body: body }
      end
    rescue Faraday::TimeoutError => e
      { error: String(e) }
    rescue Faraday::ConnectionFailed => e
      { error: String(e) }
    rescue StandardError => e
      { error: String(e) }
    end
  end
end
