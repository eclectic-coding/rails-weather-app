# Weather App

A simple Rails application that displays current weather and a 5-day forecast using the OpenWeatherMap API.

## Features

- Current weather lookup by ZIP or City/State (US)
- 5-day forecast (grouped daily summaries with high/low temps, icon, description and precipitation chance)
- Local caching of location & weather responses to reduce API requests
- Icon caching with background job: local icons stored in `public/weather_icons` with remote fallback
- Simple, responsive UI and test coverage (RSpec)

## System requirements & dependencies

- Ruby: MRI Ruby 3.2+ (use your project's Ruby manager: rbenv, rvm, asdf)
- Bundler: `gem install bundler` (Bundler 2.x compatible)
- Database: SQLite3 (development/test); the app is configured to use `sqlite3` by default
- Node / npm: Not required for importmap-based asset handling, but useful if you edit modern JS or use the optional build tools
- System libraries: `libsqlite3` development headers and a C compiler are required for the `sqlite3` gem on some platforms

Key gems and tools (declared in `Gemfile`):

- Rails ~> 8.1
- Propshaft, Importmap, Turbo, Stimulus
- Puma webserver
- Faraday HTTP client (used by the Weather API service)
- RSpec, FactoryBot (testing)
- Dartsass and Bootstrap for styling

External services:

- OpenWeatherMap API — you need an API key (see Setup above). The application uses the current weather endpoint and the 5-day forecast endpoint.

## Setup

1. Clone the repository:

```bash
git clone <repo-url> weather-app
cd weather-app
```

2. Install Ruby gems:

```bash
bundle install
```

3. Set your OpenWeather API key (one of these):

Option A — Environment variable (quick, per-shell):

```bash
# export as environment variable for development
export OPENWEATHER_API_KEY="your_api_key_here"
```

Option B — Rails encrypted credentials (recommended for checked-in deployments):

- Open the development credentials editor and add the key under a top-level name such as `weather_api_key`.

```bash
# edit encrypted credentials for the default environment (Rails will open your $EDITOR)
bin/rails credentials:edit --environment development
```

- Inside the editor add:

```yaml
# config/credentials/development.yml.enc (edited via the rails credentials command)
weather_api_key: your_api_key_here
```

- Save and close the editor; Rails will encrypt the file for you. In development you can also place the `config/master.key` or set `RAILS_MASTER_KEY` in your environment so Rails can read credentials.

The application reads the API key from credentials (preferred) or falls back to the `OPENWEATHER_API_KEY` environment variable.

4. Create and migrate the database:

```bash
bin/rails db:create db:migrate
```

5. Start the Rails server:

```bash
bin/rails server
```

Open http://localhost:3000 and use the search form to get current weather and a 5-day forecast for a ZIP code or City/State (US only).

## Tests

Run the test suite with:

```bash
bin/rspec
```

Remaining README template notes are intentionally left as TODOs.
