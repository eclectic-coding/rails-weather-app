require 'rails_helper'

RSpec.describe WeatherHelper, type: :helper do
  describe '#weather_icon_url_for' do
    it 'returns the correct icon URL when icon code present' do
      weather = { weather: [{ icon: '10d', description: 'moderate rain' }], name: 'Town' }
      expect(helper.weather_icon_url_for(weather)).to eq('https://openweathermap.org/img/wn/10d.png')
    end

    it 'returns nil when no icon present' do
      weather = { weather: [{ description: 'clear' }], name: 'Town' }
      expect(helper.weather_icon_url_for(weather)).to be_nil
    end

    it 'returns nil for non-diggable objects' do
      expect(helper.weather_icon_url_for(nil)).to be_nil
    end
  end

  describe '#weather_icon_tag' do
    it 'returns an image tag with alt and size when icon available and enqueues job' do
      weather = { weather: [{ icon: '01n', description: 'clear sky' }], name: 'Testville' }

      # ensure no cached file exists
      public_dir = Rails.root.join('public', 'weather_icons')
      FileUtils.rm_rf(public_dir) if Dir.exist?(public_dir)

      # use ActiveJob test helpers to assert job enqueued
      ActiveJob::Base.queue_adapter = :test
      expect {
        tag = helper.weather_icon_tag(weather, size: 48)
        expect(tag).to include('src="https://openweathermap.org/img/wn/01n.png"').or include('src="/weather_icons/01n.png"')
      }.to have_enqueued_job(CacheWeatherIconJob).with('01n')
    end

    it 'falls back to name when description missing for alt text and enqueues job' do
      weather = { weather: [{ icon: '02d' }], name: 'MyTown' }

      public_dir = Rails.root.join('public', 'weather_icons')
      FileUtils.rm_rf(public_dir) if Dir.exist?(public_dir)

      ActiveJob::Base.queue_adapter = :test
      expect {
        tag = helper.weather_icon_tag(weather)
        expect(tag).to include('alt="Mytown icon"').or include('alt="Mytown icon"')
      }.to have_enqueued_job(CacheWeatherIconJob).with('02d')
    end

    it 'returns nil when icon is not available' do
      weather = { weather: [{ description: 'no icon here' }], name: 'Town' }
      expect(helper.weather_icon_tag(weather)).to be_nil
    end

    it 'uses cached local icon if available' do
      # create a fake local icon file
      public_dir = Rails.root.join('public', 'weather_icons')
      FileUtils.mkdir_p(public_dir)
      local_file = public_dir.join('99x.png')
      File.binwrite(local_file, "PNGDATA")

      weather = { weather: [{ icon: '99x', description: 'weird' }], name: 'CacheTown' }
      tag = helper.weather_icon_tag(weather)
      expect(tag).to include('src="/weather_icons/99x.png"')

      # cleanup
      File.delete(local_file) if File.exist?(local_file)
    end
  end
end
