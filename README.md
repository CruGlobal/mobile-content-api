# Mobile Content API

The Mobile Content API is a set of JSON-based API endpoints to drive content for mobile applications.

## Requirements
* Docker (or Ruby 3.1 + PostgreSQL 14)

## Setup via Docker
```bash
cp .env.sample .env
docker-compose up
```
## Setup without Docker
* Create database user:
```bash
createuser mobilecontentapi
```
* Create database configuration (config/database.yml):
```yaml
development:
  adapter: postgresql
  database: mobilecontentapi_development
  username: mobilecontentapi
  min_messages: WARNING

test:
  adapter: postgresql
  database: mobilecontentapi_test
  username: mobilecontentapi
  min_messages: WARNING
```

* Setup gems and database:
```bash
cp .env.sample .env
./bin/setup
```

## Testing
Run tests with `bundle exec rspec` or set up Docker to run them automatically with Guard:
```bash
docker-compose -f docker-compose.yml -f docker-compose.test.yml up
```

## CrowdIn Integration

This application integrates with CrowdIn for translations. To use this feature, you need to:

1. Create a CrowdIn account and project
2. Get your CrowdIn API token from the CrowdIn account settings
3. Set the following environment variables:
   - `CROWDIN_API_TOKEN`: Your CrowdIn API token
   - `CROWDIN_ORGANIZATION_DOMAIN`: (Optional) Your organization domain if using CrowdIn Enterprise

Each resource can be associated with a CrowdIn project using the `crowdin_project_id` attribute.
