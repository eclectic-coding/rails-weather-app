require 'rails_helper'

RSpec.describe WeatherLookup do
  let(:search_zip) { { type: :zip, value: '02139' } }
  let(:search_city) { { type: :city_state, city: 'Cityville', state: 'MA' } }

  it 'returns weather when service returns success for zip' do
    service_double = instance_double(WeatherApiService)
    allow(WeatherApiService).to receive(:new).and_return(service_double)
    allow(service_double).to receive(:fetch_by_zip).with('02139').and_return({ name: 'Testville' })

    result = WeatherLookup.call(search_zip)
    expect(result[:weather]).to eq({ name: 'Testville' })
    expect(result[:error]).to be_nil
  end

  it 'returns error when service returns an error hash' do
    service_double = instance_double(WeatherApiService)
    allow(WeatherApiService).to receive(:new).and_return(service_double)
    allow(service_double).to receive(:fetch_by_zip).with('99999').and_return({ error: 'Not Found' })

    result = WeatherLookup.call({ type: :zip, value: '99999' })
    expect(result[:weather]).to be_nil
    expect(result[:error]).to eq('Not Found')
  end

  it 'handles missing api key (ArgumentError) gracefully' do
    allow(WeatherApiService).to receive(:new).and_raise(ArgumentError.new('missing key'))

    result = WeatherLookup.call(search_zip)
    expect(result[:weather]).to be_nil
    expect(result[:error]).to eq('missing key')
  end

  it 'returns weather when service returns success for city/state' do
    service_double = instance_double(WeatherApiService)
    allow(WeatherApiService).to receive(:new).and_return(service_double)
    allow(service_double).to receive(:fetch_by_city_and_state).with('Cityville', 'MA').and_return({ name: 'Cityville' })

    result = WeatherLookup.call(search_city)
    expect(result[:weather]).to eq({ name: 'Cityville' })
    expect(result[:error]).to be_nil
  end

  it 'handles generic exceptions from the service gracefully' do
    service_double = instance_double(WeatherApiService)
    allow(WeatherApiService).to receive(:new).and_return(service_double)
    allow(service_double).to receive(:fetch_by_zip).and_raise(StandardError.new('boom'))

    result = WeatherLookup.call(search_zip)
    expect(result[:weather]).to be_nil
    expect(result[:error]).to match(/boom/)
  end

  it 'returns cached data when a fresh LocationLookup exists' do
    # create a fresh cached record
    lookup = LocationLookup.create!(zip: '02139', latitude: 1.23, longitude: 4.56, data: { name: 'CachedTown' }, cached_at: Time.current)

    # ensure the service is not called
    expect(WeatherApiService).not_to receive(:new)

    result = WeatherLookup.call(search_zip)
    expect(result[:cached]).to be true
    expect(result[:cached_at]).not_to be_nil
    expect(result[:weather]).to eq(lookup.data_hash)
  end

  it 'calls the API and updates a stale LocationLookup' do
    # create a stale cached record older than CACHE_TTL
    stale_time = Time.current - (LocationLookup::CACHE_TTL + 1.minute)
    lookup = LocationLookup.create!(zip: '02139', latitude: 1.23, longitude: 4.56, data: { name: 'OldTown' }, cached_at: stale_time)

    service_double = instance_double(WeatherApiService)
    allow(WeatherApiService).to receive(:new).and_return(service_double)
    new_response = { name: 'FreshTown', coord: { lat: 7.89, lon: 0.12 } }
    allow(service_double).to receive(:fetch_by_zip).with('02139').and_return(new_response)

    result = WeatherLookup.call(search_zip)
    expect(result[:cached]).to be false
    expect(result[:weather]).to eq(new_response)

    lookup.reload
    expect(lookup.data_hash[:name]).to eq('FreshTown')
    expect(lookup.latitude.to_f).to eq(7.89)
  end
end
