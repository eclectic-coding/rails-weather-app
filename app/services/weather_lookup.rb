require_dependency 'weather_api_service' if defined?(require_dependency)

class WeatherLookup
  # Accepts search_info as produced by WeatherSearchForm
  # Returns a hash: { weather: parsed_result_or_nil, error: error_message_or_nil, cached: bool, cached_at: Time || nil }
  def self.call(search_info, api_key: nil, client: nil)
    cached = false
    cached_at = nil

    case search_info[:type]
    when :zip
      zip = search_info[:value]
      lookup = LocationLookup.find_fresh_by_zip(zip) rescue nil

      if lookup&.has_coords?
        # Return cached data without hitting the API
        cached = true
        cached_at = lookup.cached_at
        response = lookup.data_hash
      else
        service = ::WeatherApiService.new(api_key: api_key, client: client)
        response = service.fetch_by_zip(zip)
        persist_coords_for_zip(zip, response)
      end
    when :city_state
      city = search_info[:city]
      state = search_info[:state]
      lookup = LocationLookup.find_fresh_by_city_state(city, state) rescue nil

      if lookup&.has_coords?
        cached = true
        cached_at = lookup.cached_at
        response = lookup.data_hash
      else
        service = ::WeatherApiService.new(api_key: api_key, client: client)
        response = service.fetch_by_city_and_state(city, state)
        persist_coords_for_city_state(city, state, response)
      end
    else
      response = { error: 'Unsupported search type' }
    end

    if response.is_a?(Hash) && response[:error].present?
      { weather: nil, error: response[:error], cached: cached, cached_at: cached_at }
    else
      { weather: response, error: nil, cached: cached, cached_at: cached_at }
    end
  rescue ArgumentError => e
    { weather: nil, error: e.message.to_s, cached: false, cached_at: nil }
  rescue StandardError => e
    { weather: nil, error: e.message.to_s, cached: false, cached_at: nil }
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
  rescue StandardError => _e
    # don't let persistence failures block responding
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
  rescue StandardError => _e
    nil
  end
end
