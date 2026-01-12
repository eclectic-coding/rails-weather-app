require 'uri'
require 'json'
require_relative 'weather_api_client'

class WeatherApiService
  BASE_URL = "https://api.openweathermap.org/data/2.5/weather".freeze
  BASE_URL_FORECAST = "https://api.openweathermap.org/data/2.5/forecast".freeze

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

  # Fetch 5-day / 3-hour forecast by coordinates. Returns parsed JSON or error hash.
  def fetch_forecast_by_coords(lat, lon)
    client = WeatherApiClient.new(base_url: BASE_URL_FORECAST)
    query = { lat: lat, lon: lon, appid: @api_key, units: 'imperial' }
    begin
      res = client.get(query)
      status = res.status
      body = res.body

      if status >= 200 && status < 300
        begin
          JSON.parse(body, symbolize_names: true)
        rescue JSON::ParserError => e
          { error: "Invalid JSON response: #{e}" }
        end
      else
        parsed = begin
          JSON.parse(body, symbolize_names: true) rescue nil
        end
        message = parsed && parsed[:message] ? parsed[:message] : res.reason_phrase
        { error: "API request failed (#{status}): #{message}", raw_body: body }
      end
    rescue Faraday::TimeoutError => e
      { error: e.to_s }
    rescue Faraday::ConnectionFailed => e
      { error: e.to_s }
    rescue StandardError => e
      { error: e.to_s }
    end
  end

  # Transform raw forecast JSON into simplified daily summaries (up to 5 days)
  # Each summary: { date: Date, temp_min: Float, temp_max: Float, icon: String, description: String }
  def five_day_summaries(forecast_json)
    return [] unless forecast_json.is_a?(Hash) && forecast_json[:list].is_a?(Array)

    # Group entries by local date (using dt_txt which is in UTC)
    groups = {}
    forecast_json[:list].each do |entry|
      dt_txt = entry[:dt_txt]
      next unless dt_txt
      date = Date.parse(dt_txt) rescue nil
      next unless date

      groups[date] ||= []
      groups[date] << entry
    end

    # Build summaries sorted by date, take up to 5 days
    groups.keys.sort.map do |date|
      entries = groups[date]
      temps = entries.map { |e| e.dig(:main, :temp) }.compact
      next if temps.empty?

      temp_min = temps.min
      temp_max = temps.max

      # Pick the entry at midday or the first as representative for icon/description
      rep = entries.find { |e| e[:dt_txt].include?('12:00:00') } || entries.first
      icon = rep.dig(:weather, 0, :icon)
      description = rep.dig(:weather, 0, :description)

      # Compute precipitation probability for the day (pop is 0..1). Use the maximum pop across entries.
      pops = entries.map { |e| e[:pop] }.compact.map(&:to_f)
      pop = pops.max || 0.0

      { date: date, temp_min: temp_min, temp_max: temp_max, icon: icon, description: description, pop: pop }
    end.compact.first(5)
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
          { error: "Invalid JSON response: #{e}" }
        end
      else
        parsed = begin
          JSON.parse(body, symbolize_names: true) rescue nil
        end
        message = parsed && parsed[:message] ? parsed[:message] : res.reason_phrase
        { error: "API request failed (#{status}): #{message}", raw_body: body }
      end
    rescue Faraday::TimeoutError => e
      { error: e.to_s }
    rescue Faraday::ConnectionFailed => e
      { error: e.to_s }
    rescue StandardError => e
      { error: e.to_s }
    end
  end
end
