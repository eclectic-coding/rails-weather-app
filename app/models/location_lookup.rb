class LocationLookup < ApplicationRecord
  CACHE_TTL = 30.minutes unless const_defined?(:CACHE_TTL)

  scope :by_zip, ->(zip) { where(zip: zip.to_s.strip) }
  scope :by_city_state, ->(city, state) { where(city: city.to_s.strip, state: state.to_s.strip.upcase) }

  class JsonCoder
    def self.load(value)
      return {} if value.nil? || value == ''
      begin
        JSON.parse(value, symbolize_names: true)
      rescue StandardError
        {}
      end
    end

    def self.dump(obj)
      obj.to_json
    end
  end

  if columns_hash['data'] && columns_hash['data'].type == :text
    serialize :data, coder: JsonCoder
  end

  if columns_hash['forecast_data'] && columns_hash['forecast_data'].type == :text
    serialize :forecast_data, coder: JsonCoder
  end

  before_save :normalize_state

  def self.find_fresh_by_zip(zip)
    by_zip(zip).where('cached_at IS NOT NULL AND cached_at > ?', Time.current - CACHE_TTL).first
  end

  def self.find_fresh_by_city_state(city, state)
    by_city_state(city, state).where('cached_at IS NOT NULL AND cached_at > ?', Time.current - CACHE_TTL).first
  end

  def stale?
    cached_at.nil? || cached_at < Time.current - CACHE_TTL
  end

  def data_hash
    data || {}
  end

  def has_coords?
    latitude.present? && longitude.present?
  end

  def forecast_hash
    forecast_data || {}
  end

  def forecast_fresh?(ttl_seconds: CACHE_TTL)
    return false if forecast_data.blank?

    return false if cached_at.nil?
    cached_at > Time.current - ttl_seconds
  end

  def update_forecast!(json)
    self.forecast_data = json
    self.cached_at = Time.current
    save!
  end

  private

  def normalize_state
    self.state = state.to_s.strip.upcase if state.present?
  end
end
