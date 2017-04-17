# frozen_string_literal: true

class CustomPagesController < SecureController
  def create
    head(upsert_custom_page)
  end

  def destroy
    custom_page = CustomPage.find(params[:id])
    custom_page.destroy
  end

  private

  def upsert_custom_page
    CustomPage.create!(params.permit(:translation_id, :page_id, :structure))
    return :created
  rescue ActiveRecord::RecordNotUnique
    existing = CustomPage.find_by(translation_id: params[:translation_id], page_id: params[:page_id])
    existing.update(params.permit(:structure))
    return :no_content
  end
end
