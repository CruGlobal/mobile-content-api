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
    attrs = params[:data][:attributes]

    CustomPage.create!(attrs.permit(:translation_id, :page_id, :structure))
    return :created
  rescue ActiveRecord::RecordInvalid
    existing = CustomPage.find_by(translation_id: attrs[:translation_id], page_id: attrs[:page_id])
    existing.update(attrs.permit(:structure))
    return :no_content
  end
end
