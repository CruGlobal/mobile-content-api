class RulePraxisController < ApplicationController
  before_action :authorize!

  def create
    create_rule_praxis
  rescue ActiveRecord::RecordInvalid => e
    render json: {error: e.record.errors}, status: :unprocessable_entity
  end

  def update
    update_rule_praxis
  end

  private

  def create_rule_praxis
    created = RulePraxi.create!(permit_params(:tool_group_id, :negative_rule, :openness => [], :confidence => []))
    response.headers["Location"] = "tool_groups/#{created.id}"
    render json: created, status: :created
  end

  def update_rule_praxis
    existing = RulePraxi.find(params[:id])
    existing.update!(permit_params(:negative_rule, :openness => [], :confidence => []))
    render json: existing, status: :accepted
  end

end
