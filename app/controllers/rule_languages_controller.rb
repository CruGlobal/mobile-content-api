class RuleLanguagesController < ApplicationController
  before_action :authorize!

  def create
    create_rule_language
  rescue ActiveRecord::RecordInvalid => e
    render json: {error: e.record.errors}, status: :unprocessable_entity
  end

  def update
    update_rule_language
  end

  def destroy
    rule_language = RuleLanguage.find(params[:id])
    rule_language.destroy!
    head :no_content
  end

  private

  def create_rule_language
    created = RuleLanguage.create!(permit_params(:tool_group_id, :negative_rule, :languages => []))
    response.headers["Location"] = "tool_groups/#{created.id}"
    render json: created, status: :created
  end

  def update_rule_language
    existing = RuleLanguage.find(params[:id])
    existing.update!(permit_params(:negative_rule, :languages => []))
    render json: existing, status: :accepted
  end
end
