# frozen_string_literal: true

class PagesController < SecureController
  skip_before_action :authorize!, only: [ :publish, :subscribe ]

  def create
    p = Page.create!(params.require(:data).require(:attributes)
                       .permit(:filename, :structure, :resource_id, :position))

    response.headers["Location"] = "pages/#{p.id}"
    render json: p, status: :created
  end

  def update
    page = Page.find(params[:id])
    page.update!(params.require(:data).require(:attributes).permit(:structure))
    render json: page, status: :ok
  end

  def publish
  end

  def subscribe
  end
end
