# OneSky to CrowdIn Migration Guide

This document outlines the changes made to migrate from OneSky to CrowdIn for translations in this application.

## Database Migration

A migration file has been created (`db/migrate/20240529135120_rename_onesky_to_crowdin.rb`) that:

1. Renames `onesky_project_id` to `crowdin_project_id` in the `resources` table
2. Renames `onesky_phrase_id` to `crowdin_phrase_id` in the `translated_attributes` table if it exists

## API Integration

The OneSky module has been replaced with a CrowdIn module that implements the same interface. The new module uses the [CrowdIn API Ruby Client](https://github.com/crowdin/crowdin-api-client-ruby) to interact with the CrowdIn API.

### Environment Variables

The following environment variables have been replaced:

- `ONESKY_API_KEY` and `ONESKY_API_SECRET` → `CROWDIN_API_TOKEN`
- Added optional `CROWDIN_ORGANIZATION_DOMAIN` for CrowdIn Enterprise users

## Code Changes

The following files have been updated:

1. New files created:
   - `app/lib/crowdin.rb`: Implementation of the CrowdIn API integration
   - `spec/lib/crowdin_spec.rb`: Tests for the CrowdIn integration
   - `app/validators/uses_crowdin_validator.rb`: Validator for CrowdIn resources

2. Renamed methods:
   - `Resource#uses_onesky?` → `Resource#uses_crowdin?`
   - `PageClient#push_new_onesky_translation` → `PageClient#push_new_crowdin_translation`
   - `Translation#name_desc_onesky` → `Translation#name_desc_crowdin`

3. Updated references:
   - Updated all references to `onesky_project_id` to `crowdin_project_id`
   - Updated all references to `onesky_phrase_id` to `crowdin_phrase_id`
   - Updated all error messages referring to OneSky to refer to CrowdIn

## Testing

Tests have been updated to mock CrowdIn API calls instead of OneSky API calls.

## Migration Steps for Users

1. Create a CrowdIn account and project
2. Get your CrowdIn API token from the CrowdIn account settings
3. Set the environment variables:
   - `CROWDIN_API_TOKEN`: Your CrowdIn API token
   - `CROWDIN_ORGANIZATION_DOMAIN`: (Optional) Your organization domain if using CrowdIn Enterprise
4. Run the database migration
5. Update your Resource records to have the correct CrowdIn project IDs 