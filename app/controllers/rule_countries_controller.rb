class RuleCountriesController < ApplicationController
  before_action :authorize!

  def create
    create_rule_country
  rescue ActiveRecord::RecordInvalid => e
    render json: {error: e.record.errors}, status: :unprocessable_entity
  end

  def update
    update_rule_country
  end

  def destroy
    rule_country = RuleCountry.find(params[:id])
    rule_country.destroy!
    head :no_content
  end

  private

  def create_rule_country
    created = RuleCountry.create!(permit_params(:tool_group_id, :negative_rule, :countries => []))
    response.headers["Location"] = "tool_groups/#{created.id}"
    render json: created, status: :created
  end

  def update_rule_country
    existing = RuleCountry.find(params[:id])
    existing.update!(permit_params(:negative_rule, :countries => []))
    render json: existing, status: :accepted
  end
end
