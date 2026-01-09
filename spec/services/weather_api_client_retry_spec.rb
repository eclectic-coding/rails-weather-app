require 'rails_helper'

RSpec.describe WeatherApiClient do
  let(:base) { WeatherApiService::BASE_URL }

  it 'retries when the first response is a retriable status and then succeeds' do
    client = build_test_client(base_url: base, retry_options: { max: 1, interval: 0.0, interval_randomness: 0.0, backoff_factor: 1.0, retry_statuses: [500], exceptions: [] })

    conn = client.instance_variable_get(:@conn)

    resp1 = double('resp1', status: 500, body: '{"message":"server error"}', reason_phrase: 'Internal Server Error')
    resp2 = double('resp2', status: 200, body: '{"name":"RetryTown"}', reason_phrase: 'OK')

    calls = 0
    allow(conn).to receive(:get) do |*_args|
      calls += 1
      calls == 1 ? resp1 : resp2
    end

    result = client.get(q: 'something')
    expect(result.status).to eq(200)
    expect(JSON.parse(result.body)['name']).to eq('RetryTown')
    expect(calls).to eq(2)
  end

  it 'retries when the first call raises a retryable exception and then succeeds' do
    client = build_test_client(base_url: base, retry_options: { max: 1, interval: 0.0, interval_randomness: 0.0, backoff_factor: 1.0, retry_statuses: [], exceptions: [Faraday::ConnectionFailed] })

    conn = client.instance_variable_get(:@conn)

    resp_ok = double('resp_ok', status: 200, body: '{"name":"RecoveredCity"}', reason_phrase: 'OK')

    calls = 0
    allow(conn).to receive(:get) do |*_args|
      calls += 1
      if calls == 1
        raise Faraday::ConnectionFailed.new('connection refused')
      else
        resp_ok
      end
    end

    result = client.get(q: 'something')
    expect(result.status).to eq(200)
    expect(JSON.parse(result.body)['name']).to eq('RecoveredCity')
    expect(calls).to eq(2)
  end
end
