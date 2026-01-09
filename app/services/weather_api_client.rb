require 'faraday'
require 'ostruct'

class WeatherApiClient
  DEFAULT_OPEN_TIMEOUT = 5
  DEFAULT_TIMEOUT = 5

  DEFAULT_RETRY_OPTIONS = {
    max: 2,
    interval: 0.5,
    interval_randomness: 0.5,
    backoff_factor: 2,
    retry_statuses: [429, 500, 502, 503, 504],
    exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed]
  }.freeze

  # Helper factory for tests that want a client with no retry sleeps
  def self.build_for_test(base_url: nil, adapter: Faraday.default_adapter)
    base = base_url || WeatherApiService::BASE_URL rescue nil
    retry_opts = {
      max: 0,
      interval: 0.0,
      interval_randomness: 0.0,
      backoff_factor: 1.0,
      retry_statuses: [],
      exceptions: []
    }
    new(base_url: base, adapter: adapter, retry_options: retry_opts)
  end

  def initialize(base_url:, open_timeout: DEFAULT_OPEN_TIMEOUT, timeout: DEFAULT_TIMEOUT, adapter: Faraday.default_adapter, retry_options: {})
    @base_url = base_url
    @retry_options = DEFAULT_RETRY_OPTIONS.merge(retry_options)

    @conn = Faraday.new(url: base_url) do |f|
      f.request :url_encoded
      f.adapter adapter
      f.options.open_timeout = open_timeout
      f.options.timeout = timeout
    end
  end

  def get(params = {})
    attempts = 0
    max_attempts = @retry_options[:max].to_i + 1
    interval = @retry_options[:interval].to_f
    randomness = @retry_options[:interval_randomness].to_f
    backoff = @retry_options[:backoff_factor].to_f
    retry_statuses = Array(@retry_options[:retry_statuses])
    retry_exceptions = Array(@retry_options[:exceptions])

    last_exception = nil

    while attempts < max_attempts
      begin
        res = @conn.get do |req|
          req.params.update(params)
        end

        status = res.status
        body = res.body
        reason = res.reason_phrase

        if retry_statuses.include?(status) && (attempts + 1) < max_attempts
          attempts += 1
          sleep_with_jitter(interval, randomness, backoff, attempts)
          next
        end

        return OpenStruct.new(status: status, body: body, reason_phrase: reason)
      rescue *retry_exceptions => e
        last_exception = e
        attempts += 1
        if attempts < max_attempts
          sleep_with_jitter(interval, randomness, backoff, attempts)
          next
        else
          # re-raise after exhausting retries
          raise e
        end
      end
    end

    raise last_exception if last_exception
    raise "WeatherApiClient: failed to get a response"
  end

  private

  def sleep_with_jitter(interval, randomness, backoff, attempts)
    base = interval * (backoff**(attempts - 1))
    jitter = base * randomness * rand
    sleep(base + jitter)
  end
end
