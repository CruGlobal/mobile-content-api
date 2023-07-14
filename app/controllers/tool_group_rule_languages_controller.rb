class ToolGroupRuleLanguagesController < ApplicationController
  before_action :authorize!

  def create
    create_tool_group_rule_language
  rescue ActiveRecord::RecordInvalid => e
    render json: {error: e.record.errors}, status: :unprocessable_entity
  end

  def update
    update_tool_group_rule_language
  end

  def destroy
    tool_group_rule_language = ToolGroupRuleLanguage.find(params[:id])
    tool_group_rule_language.destroy!
    head :no_content
  end

  private

  def create_tool_group_rule_language
    created = ToolGroupRuleLanguage.create!(permit_params(:tool_group_id, :negative_rule, :languages => []))
    response.headers["Location"] = "tool_groups/#{created.id}"
    render json: created, status: :created
  end

  def update_tool_group_rule_language
    existing = ToolGroupRuleLanguage.find(params[:id])
    existing.update!(permit_params(:negative_rule, :languages => []))
    render json: existing, status: :accepted
  end
end
