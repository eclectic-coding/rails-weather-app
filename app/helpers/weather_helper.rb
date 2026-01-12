module WeatherHelper
  def weather_icon_url_for(weather)
    return nil unless weather.respond_to?(:dig)

    icon_code = weather.dig(:weather, 0, :icon).to_s.presence
    return nil unless icon_code

    "https://openweathermap.org/img/wn/#{icon_code}.png"
  end

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

    if defined?(CacheWeatherIconJob)
      CacheWeatherIconJob.perform_later(icon_code)
    end

    weather_icon_url_for(weather)
  end

  def weather_icon_tag(weather, size: 64, **options)
    url = cached_weather_icon_url_for(weather)
    return nil unless url

    desc = weather.dig(:weather, 0, :description).to_s.presence || weather[:name].to_s.presence || 'Weather'
    alt_text = "#{desc.to_s.capitalize} icon"

    image_tag(url, { alt: alt_text, width: size, height: size }.merge(options))
  end

  def wind_direction(degrees)
    return nil if degrees.nil?

    d = degrees.to_f % 360
    directions = %w[N NE E SE S SW W NW]
    index = ((d + 22.5) / 45.0).floor % directions.length
    directions[index]
  end

  def display_temperature(weather)
    return nil unless weather.respond_to?(:dig)

    temp = weather&.dig(:main, :temp)
    return nil if temp.nil?

    value = temp.to_f
    formatted = (value == value.to_i) ? value.to_i.to_s : sprintf('%.1f', value)
    "#{formatted} °F"
  end

  def display_wind(weather)
    return nil unless weather.respond_to?(:dig)

    speed = weather&.dig(:wind, :speed)
    return nil if speed.nil?

    deg = weather&.dig(:wind, :deg)
    label = wind_direction(deg)

    if label.present?
      "#{speed.to_f.round} mph #{label}"
    else
      "#{speed.to_f.round} mph"
    end
  end
end
