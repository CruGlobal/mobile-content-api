# frozen_string_literal: true

class PagesController < SecureController
  def create
    p = Page.create!(params.require(:data).require(:attributes)
                       .permit(:filename, :structure, :resource_id, :position))

    response.headers["Location"] = "pages/#{p.id}"
    render json: p, status: :created
  end

  def update
    page = Page.find(params[:id])
    page.update!(params.require(:data).require(:attributes).permit(:structure, :filename))
    render json: page, status: :ok
  end

  def reorder
    resource = Resource.find(params[:resource_id])
    ordered_ids = params.require(:data).require(:attributes).require(:page_ids).map(&:to_i)

    Page.transaction do
      unless ordered_ids.sort == resource.pages.lock.pluck(:id).sort
        raise Error::BadRequestError, "page_ids must contain exactly the ids of the resource's pages"
      end

      # park all positions at unique negative values to avoid colliding with the
      # (position, resource_id) unique index, then assign the final 0..n-1 order
      resource.pages.update_all("position = -position - 1")
      ordered_ids.each_with_index do |page_id, index|
        Page.where(id: page_id).update_all(position: index)
      end
      resource.touch
    end

    render json: resource.pages.order(:position), status: :ok
  end
end
