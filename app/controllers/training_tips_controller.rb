class TrainingTipsController < WithUserController
  before_action :convert_hyphen_to_dash, only: [:create, :update]

  def create
    user_training_tip = @user.user_training_tips.create!(permitted_params)
    response.headers["Location"] = "users/#{@user.id}/training-tips/#{user_training_tip.id}"
    render json: user_training_tip, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: {errors: formatted_errors("record_invalid", e)}, status: :unprocessable_content
  end

  def update
    user_training_tip = @user.user_training_tips.find(params[:id])
    user_training_tip.update!(permitted_params)
    response.headers["Location"] = "users/me/training-tips/#{user_training_tip.id}"
    render json: user_training_tip
  end

  def destroy
    user_training_tip = @user.user_training_tips.find(params[:id])
    user_training_tip.destroy!
    head :no_content
  end

  protected

  def permitted_params
    tool_id = params.dig(:data, :relationships, :tool, :data, :id).to_i
    language_id = params.dig(:data, :relationships, :language, :data, :id).to_i
    permit_params(:tip_id, :is_completed).merge(tool_id: tool_id, language_id: language_id)
  end
end
