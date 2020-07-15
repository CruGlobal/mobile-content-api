# frozen_string_literal: true

class CustomTipsController < SecureController
  def create
    create_custom_tip
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    update_custom_tip
  end

  def destroy
    custom_tip = CustomTip.find(params[:id])
    custom_tip.destroy!
    head :no_content
  end

  private

  def create_custom_tip
    created = CustomTip.create!(permit_params(:language_id, :tip_id, :structure))
    response.headers["Location"] = "custom_tips/#{created.id}"
    render json: created, status: :created
  end

  def update_custom_tip
    existing = CustomTip.find_by(language_id: data_attrs[:language_id], tip_id: data_attrs[:tip_id])
    existing.update!(permit_params(:structure))
    render json: existing, status: :ok
  end
end
