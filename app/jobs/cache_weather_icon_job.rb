class CacheWeatherIconJob < ApplicationJob
  queue_as :default

  # icon_code: string like '10d'
  def perform(icon_code)
    return if icon_code.blank?

    public_dir = Rails.root.join('public', 'weather_icons')
    FileUtils.mkdir_p(public_dir) unless Dir.exist?(public_dir)

    local_path = public_dir.join("#{icon_code}.png")
    return if File.exist?(local_path)

    remote = "https://openweathermap.org/img/wn/#{icon_code}.png"
    begin
      resp = Faraday.get(remote)
      if resp.status >= 200 && resp.status < 300 && resp.body
        File.binwrite(local_path, resp.body)
      end
    rescue StandardError => e
      Rails.logger.debug("CacheWeatherIconJob failed to download #{remote}: #{e.message}") if defined?(Rails)
    end
  end
end
