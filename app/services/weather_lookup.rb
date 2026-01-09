class WeatherLookup
  # Accepts search_info as produced by WeatherSearchForm
  # Returns a hash: { weather: parsed_result_or_nil, error: error_message_or_nil }
  def self.call(search_info, api_key: nil, client: nil)
    service = ::WeatherApiService.new(api_key: api_key, client: client)

    response = case search_info[:type]
               when :zip
                 service.fetch_by_zip(search_info[:value])
               when :city_state
                 service.fetch_by_city_and_state(search_info[:city], search_info[:state])
               else
                 { error: 'Unsupported search type' }
               end

    if response.is_a?(Hash) && response[:error].present?
      { weather: nil, error: response[:error] }
    else
      { weather: response, error: nil }
    end
  rescue ArgumentError => e
    { weather: nil, error: e.message.to_s }
  rescue StandardError => e
    { weather: nil, error: e.message.to_s }
  end
end
