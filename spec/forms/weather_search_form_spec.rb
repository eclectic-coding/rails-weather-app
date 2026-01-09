require 'rails_helper'

RSpec.describe WeatherSearchForm do
  it 'returns nil search_info when no params provided' do
    form = WeatherSearchForm.new({})
    expect(form.search_info).to be_nil
    expect(form.errors).to be_empty
  end

  it 'validates and returns zip search_info when zip provided' do
    form = WeatherSearchForm.new(zip: '02139')
    expect(form.search_info).to eq({ type: :zip, value: '02139' })
    expect(form.errors).to be_empty
  end

  it 'rejects invalid zip' do
    form = WeatherSearchForm.new(zip: '123')
    expect(form.search_info).to be_nil
    expect(form.errors).to include('ZIP code must be 5 digits (US only).')
  end

  it 'validates city/state pair' do
    form = WeatherSearchForm.new(city: 'Cambridge', state: 'MA')
    expect(form.search_info).to eq({ type: :city_state, city: 'Cambridge', state: 'MA' })
    expect(form.errors).to be_empty
  end

  it 'rejects missing state with city present' do
    form = WeatherSearchForm.new(city: 'Cambridge', state: '')
    expect(form.search_info).to be_nil
    expect(form.errors).to include('Both city and state are required when searching by city/state.')
  end

  it 'rejects invalid state code' do
    form = WeatherSearchForm.new(city: 'City', state: 'XYZ')
    expect(form.search_info).to be_nil
    expect(form.errors).to include('State must be the 2-letter US state code (e.g. MA, NY).')
  end

  it 'trims whitespace from inputs' do
    form = WeatherSearchForm.new(zip: ' 02139 ')
    expect(form.search_info).to eq({ type: :zip, value: '02139' })

    form2 = WeatherSearchForm.new(city: '  Cityville  ', state: ' ma ')
    expect(form2.search_info).to eq({ type: :city_state, city: 'Cityville', state: 'MA' })
  end

  it 'gives precedence to ZIP when both zip and city/state are provided' do
    form = WeatherSearchForm.new(zip: '02139', city: 'Nowhere', state: 'ZZ')
    expect(form.search_info).to eq({ type: :zip, value: '02139' })
    expect(form.errors).to be_empty
  end

  it 'upcases lowercase state codes' do
    form = WeatherSearchForm.new(city: 'Town', state: 'ny')
    expect(form.search_info).to eq({ type: :city_state, city: 'Town', state: 'NY' })
    expect(form.errors).to be_empty
  end
end
