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
    tool_group = ToolGroup.find(params[:tool_group_id])
    rule_country = tool_group.rule_countries.find(params[:id])
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
    tool_group = ToolGroup.find(params[:tool_group_id])
    existing = tool_group.rule_countries.find(params[:id])
    existing.update!(permit_params(:negative_rule, :countries => []))
    render json: existing, status: :accepted
  end
end
