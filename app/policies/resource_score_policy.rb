# frozen_string_literal: true

# Edit access to ResourceScores is scoped by (country, language).
#
# Admins are a superuser bypass and keep unrestricted access. Everyone else needs
# a matching ResourceScorePermission grant.
class ResourceScorePolicy < ApplicationPolicy
  # Reads are public (ResourceScoresController#index is unauthenticated).
  def index? = true

  def show? = true

  def create? = permitted?(record.country, record.language_id)

  def destroy? = permitted?(record.country, record.language_id)

  # An update has to clear two bars: the user must be allowed to touch the score
  # where it currently lives, AND allowed to put it where it is being moved to.
  # Checking only the target would let a us/en editor capture an existing vn/vi
  # score; checking only the source would let them push it out to vn/vi.
  def update?
    permitted?(record.country_was, record.language_id_was) &&
      permitted?(record.country, record.language_id)
  end

  # The mass endpoints rewrite every score in one (country, language,
  # resource_type) slice, so a single check on that slice covers every row the
  # transaction creates, updates, or destroys.
  def mass_update? = create?

  def mass_update_ranked? = create?

  private

  def permitted?(country, language_id)
    return false if user.nil?
    return true if user.admin?
    return false if country.blank?

    user.resource_score_permissions.any? { |grant| grant.covers?(country, language_id) }
  end
end
