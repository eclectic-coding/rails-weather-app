require_dependency 'weather_api_service' if defined?(require_dependency)

class WeatherLookup
  def self.call(search_info, api_key: nil, client: nil)
    cached = false
    cached_at = nil

    case search_info[:type]
    when :zip
      zip = search_info[:value]
      lookup = LocationLookup.find_fresh_by_zip(zip) rescue nil

      if lookup&.has_coords?
        cached = true
        cached_at = lookup.cached_at
        response = lookup.data_hash
        forecast_summaries = lookup.forecast_hash && lookup.forecast_hash[:list] ? ::WeatherApiService.new(api_key: api_key, client: client).five_day_summaries(lookup.forecast_hash) : []
      else
        service = ::WeatherApiService.new(api_key: api_key, client: client)
        response = service.fetch_by_zip(zip)
        lookup = persist_coords_for_zip(zip, response)
        forecast_summaries = lookup ? fetch_and_persist_forecast_for_lookup(lookup, service) : []
      end
    when :city_state
      city = search_info[:city]
      state = search_info[:state]
      lookup = LocationLookup.find_fresh_by_city_state(city, state) rescue nil

      if lookup&.has_coords?
        cached = true
        cached_at = lookup.cached_at
        response = lookup.data_hash
        forecast_summaries = lookup.forecast_hash && lookup.forecast_hash[:list] ? ::WeatherApiService.new(api_key: api_key, client: client).five_day_summaries(lookup.forecast_hash) : []
      else
        service = ::WeatherApiService.new(api_key: api_key, client: client)
        response = service.fetch_by_city_and_state(city, state)
        lookup = persist_coords_for_city_state(city, state, response)
        forecast_summaries = lookup ? fetch_and_persist_forecast_for_lookup(lookup, service) : []
      end
    else
      response = { error: 'Unsupported search type' }
      forecast_summaries = []
    end

    if response.is_a?(Hash) && response[:error].present?
      { weather: nil, error: response[:error], cached: cached, cached_at: cached_at, forecast: forecast_summaries }
    else
      { weather: response, error: nil, cached: cached, cached_at: cached_at, forecast: forecast_summaries }
    end
  rescue ArgumentError => e
    { weather: nil, error: e.message.to_s, cached: false, cached_at: nil, forecast: [] }
  rescue StandardError => e
    { weather: nil, error: e.message.to_s, cached: false, cached_at: nil, forecast: [] }
  end

  def self.persist_coords_for_zip(zip, response)
    return unless response.is_a?(Hash) && response[:coord]

    lat = response.dig(:coord, :lat)
    lon = response.dig(:coord, :lon)
    return if lat.nil? || lon.nil?

    rec = LocationLookup.find_or_initialize_by(zip: zip)
    rec.latitude = lat
    rec.longitude = lon
    rec.data = response
    rec.cached_at = Time.current
    rec.save
    rec
  rescue StandardError => _e
    nil
  end

  def self.persist_coords_for_city_state(city, state, response)
    return unless response.is_a?(Hash) && response[:coord]

    lat = response.dig(:coord, :lat)
    lon = response.dig(:coord, :lon)
    return if lat.nil? || lon.nil?

    rec = LocationLookup.find_or_initialize_by(city: city.to_s.strip, state: state.to_s.strip.upcase)
    rec.zip = rec.zip || nil
    rec.latitude = lat
    rec.longitude = lon
    rec.data = response
    rec.cached_at = Time.current
    rec.save
    rec
  rescue StandardError => _e
    nil
  end

  def self.fetch_and_persist_forecast_for_lookup(lookup, service)
    return [] unless lookup&.has_coords?

    return [] unless service.respond_to?(:fetch_forecast_by_coords) && service.respond_to?(:five_day_summaries)

    begin
      forecast_json = service.fetch_forecast_by_coords(lookup.latitude, lookup.longitude)
      if forecast_json.is_a?(Hash) && forecast_json[:error].present?
        return []
      end

      lookup.update_forecast!(forecast_json)
      service.five_day_summaries(forecast_json)
    rescue StandardError => _e
      []
    end
  end
end
