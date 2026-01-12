class WeatherSearchForm
  attr_reader :zip, :city, :state, :errors

  ZIP_REGEX = /\A\d{5}\z/
  STATE_REGEX = /\A[a-zA-Z]{2}\z/

  def initialize(params = {})
    @zip = params[:zip].to_s.strip
    @city = params[:city].to_s.strip
    @state = params[:state].to_s.strip
    @errors = []

    validate
  end

  def search_info
    return nil unless valid?

    if zip_present?
      { type: :zip, value: zip }
    elsif city.present? && state.present?
      { type: :city_state, city: city, state: state.upcase }
    else
      nil
    end
  end

  def valid?
    @errors.empty?
  end

  private

  def zip_present?
    @zip && !@zip.empty?
  end

  def validate
    if zip_present?
      unless @zip.match?(ZIP_REGEX)
        @errors << 'ZIP code must be 5 digits (US only).'
      end
    elsif city.present? || state.present?
      if city.empty? || state.empty?
        @errors << 'Both city and state are required when searching by city/state.'
      elsif !state.match?(STATE_REGEX)
        @errors << 'State must be the 2-letter US state code (e.g. MA, NY).'
      end
    end
  end
end
