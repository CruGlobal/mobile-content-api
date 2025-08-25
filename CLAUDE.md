# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Setup and Installation
- `bundle install` - Install Ruby gems
- `bin/setup` - Complete development environment setup (includes database setup)
- `rails db:create db:schema:load` - Alternative database setup for fresh installs

### Testing
- `bundle exec rspec` - Run the full test suite
- `bundle exec rspec spec/path/to/specific_spec.rb` - Run a specific test file
- `bundle exec rspec spec/path/to/specific_spec.rb:line_number` - Run a specific test

### Code Quality and Linting
- `bundle exec standardrb` - Run Ruby style linter (StandardRB)
- `bundle exec standardrb --format simple` - Run StandardRB with simplified output
- `bundle exec brakeman -A -q --ensure-latest --no-pager` - Run security analysis
- `bundle exec bundle audit check --update` - Check for security vulnerabilities in dependencies

### Development Server
- `rails server` or `rails s` - Start the development server
- `bin/rails restart` - Restart the Rails application

### Database
- `rails db:migrate` - Run pending database migrations
- `rails db:prepare` - Setup database (creates if needed, runs migrations)
- `rails db:seed` - Load seed data

## Architecture Overview

This is a **Rails 7.1 API application** that serves as a mobile content management system for Christian ministry tools and resources.

### Core Domain Models
- **Resources** - Main content entities (tracts, lessons, training materials)
- **Translations** - Localized versions of resources with OneSky integration
- **Pages/Custom Pages** - Individual content pages within resources
- **Users** - Authentication and user management with multiple OAuth providers
- **Tool Groups** - Categorization and filtering system for resources

### Key Integrations
- **OneSky** - Translation management service (app/lib/one_sky.rb)
- **Adobe Campaign** - Marketing automation (app/services/adobe_campaign.rb)
- **AWS S3** - File storage via Active Storage
- **Sidekiq** - Background job processing
- **Redis** - Caching and Sidekiq backend
- **PostgreSQL** - Primary database

### Authentication Services
Multiple OAuth providers supported through service classes in `app/services/`:
- Apple ID (apple_auth_service.rb)
- Google (google_auth_service.rb) 
- Facebook (facebook_auth_service.rb)
- Okta (okta_auth_service.rb)

### API Structure
- Uses **Active Model Serializers** with JSON API format
- RESTful controllers under `app/controllers/`
- Secure endpoints inherit from `SecureController` for authentication
- API documentation generated via RSpec API Documentation

### Background Jobs
- **Sidekiq Pro** for job processing
- Translation publishing handled by `PublishTranslationJob`
- Redis configuration in `config/redis.yml`

### File Organization
- `app/lib/` - Custom business logic (OneSky, XML utilities, analytics)
- `app/services/` - Service objects for external integrations
- `app/validators/` - Custom validation logic
- `spec/acceptance/` - API integration tests
- `schema_tests/` - XML schema validation tests

### Environment Requirements
Key environment variables needed:
- AWS credentials and `MOBILE_CONTENT_API_BUCKET`
- OneSky API credentials (`ONESKY_API_KEY`, `ONESKY_API_SECRET`)
- Adobe Analytics configuration
- `BUNDLE_GEMS__CONTRIBSYS__COM` for Sidekiq Pro access

### Branch Strategy
- Main branch: `master`
- Current working branch: `rails71` (Rails 7.1 upgrade)
- CI/CD runs on pushes to `master` and `staging` branches