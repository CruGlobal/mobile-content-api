class ToolGroupRuleLanguagesController < ApplicationController
  before_action :authorize!

  def create
    create_tool_group_rule_language
  rescue ActiveRecord::RecordInvalid => e
    render json: {error: e.record.errors}, status: :unprocessable_entity
  end

  private

  def create_tool_group_rule_language
    created = ToolGroupRuleLanguage.create!(permit_params(:tool_group_id, :negative_rule, :languages => []))
    response.headers["Location"] = "tool_groups/#{created.id}"
    render json: created, status: :created
  end
end
