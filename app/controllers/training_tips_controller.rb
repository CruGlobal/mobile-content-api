class TrainingTipsController < ApplicationController
  before_action :authorize!
  before_action :convert_hyphen_to_dash, only: [:create]

  def create
    create_training_tip
  end

  private

  def create_training_tip
    created = TrainingTip.create!(permit_params(:tool, :locale, :tip_id, :is_completed))
    response.headers["Location"] = "tool_groups/#{created.id}"
    render json: created, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: {errors: formatted_errors("record_invalid", e)}, status: :unprocessable_entity
  end
end
