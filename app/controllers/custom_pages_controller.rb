# frozen_string_literal: true

class CustomPagesController < SecureController
  def create
    create_custom_page
  rescue ActiveRecord::RecordInvalid
    update_custom_page
  end

  def destroy
    custom_page = CustomPage.find(params[:id])
    custom_page.destroy!
    head :no_content
  end

  private

  def create_custom_page
    created = CustomPage.create!(data_attrs.permit(:language_id, :page_id, :structure))
    response.headers['Location'] = "custom_pages/#{created.id}"
    render json: created, status: :created
  end

  def update_custom_page
    existing = CustomPage.find_by(language_id: data_attrs[:language_id], page_id: data_attrs[:page_id])
    existing.update!(data_attrs.permit(:structure))
    render json: existing, status: :ok
  end
end
