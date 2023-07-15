class RulePraxisController < ApplicationController
  before_action :authorize!

  def create
    create_rule_praxis
  rescue ActiveRecord::RecordInvalid => e
    render json: {error: e.record.errors}, status: :unprocessable_entity
  end

  private

  def create_rule_praxis
    created = RulePraxi.create!(permit_params(:tool_group_id, :negative_rule, :openness => [], :confidence => []))
    response.headers["Location"] = "tool_groups/#{created.id}"
    render json: created, status: :created
  end
end
