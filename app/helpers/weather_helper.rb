module WeatherHelper
  # Returns the OpenWeatherMap icon URL for the given weather hash (or nil)
  def weather_icon_url_for(weather)
    return nil unless weather.respond_to?(:dig)

    icon_code = weather.dig(:weather, 0, :icon).to_s.presence
    return nil unless icon_code

    "https://openweathermap.org/img/wn/#{icon_code}.png"
  end

  # Returns the URL to a locally cached icon (if present) or remote URL as fallback.
  # If the local cache is missing, enqueue a background job to download it and return the remote URL immediately.
  def cached_weather_icon_url_for(weather)
    return nil unless weather.respond_to?(:dig)

    icon_code = weather.dig(:weather, 0, :icon).to_s.presence
    return nil unless icon_code

    public_dir = Rails.root.join('public', 'weather_icons')
    FileUtils.mkdir_p(public_dir) unless Dir.exist?(public_dir)

    local_path = public_dir.join("#{icon_code}.png")
    web_path = "/weather_icons/#{icon_code}.png"

    if File.exist?(local_path)
      return web_path
    end

    # Enqueue background job to fetch the icon asynchronously
    if defined?(CacheWeatherIconJob)
      CacheWeatherIconJob.perform_later(icon_code)
    end

    # Return remote URL as fallback while background job runs
    weather_icon_url_for(weather)
  end

  # Returns an image_tag for the weather icon or nil if not available
  # Uses a cached local copy if available or enqueues background fetch otherwise
  def weather_icon_tag(weather, size: 64, **options)
    url = cached_weather_icon_url_for(weather)
    return nil unless url

    # Prefer the weather description, then the location name, then a generic label
    desc = weather.dig(:weather, 0, :description).to_s.presence || weather[:name].to_s.presence || 'Weather'
    alt_text = "#{desc.to_s.capitalize} icon"

    image_tag(url, { alt: alt_text, width: size, height: size }.merge(options))
  end
end
