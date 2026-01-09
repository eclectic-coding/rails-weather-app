class WeatherController < ApplicationController
  # GET / or /weather
  def index
    form = WeatherSearchForm.new(params)
    @error = form.errors.first
    @search_info = form.search_info
    @weather_result = nil
    @api_error = nil
    @cached = false
    @cached_at = nil

    return unless @search_info.present?

    result = WeatherLookup.call(@search_info)
    @weather_result = result[:weather]
    @api_error = result[:error]
    @cached = result[:cached]
    @cached_at = result[:cached_at]
  end

  private

  def valid_us_zip?(zip)
    zip.match?(/\A\d{5}\z/)
  end

  def valid_us_state_code?(state)
    state.match?(/\A[a-zA-Z]{2}\z/)
  end
end
