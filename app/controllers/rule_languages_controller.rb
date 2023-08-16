class RuleLanguagesController < ApplicationController
  before_action :authorize!
  before_action :convert_hyphen_to_dash, only: [:create, :update]

  def create
    create_rule_language
  end

  def update
    update_rule_language
  end

  def destroy
    tool_group = ToolGroup.find(params[:tool_group_id])
    rule_language = tool_group.rule_languages.find(params[:id])
    rule_language.destroy!
    head :no_content
  end

  private

  def create_rule_language
    tool_group = ToolGroup.find(params[:tool_group_id])
    created = tool_group.rule_languages.create!(permit_params(:tool_group_id, :negative_rule, languages: []))
    response.headers["Location"] = "tool_groups/#{created.id}"
    render json: created, status: :created
  rescue ActiveRecord::RecordNotFound => e
    render json: formatted_errors("record_not_found", e), status: :not_found
  end

  def update_rule_language
    tool_group = ToolGroup.find(params[:tool_group_id])
    existing = tool_group.rule_languages.find(params[:id])
    existing.update!(permit_params(:negative_rule, languages: []))
    render json: existing, status: :accepted
  end
end
