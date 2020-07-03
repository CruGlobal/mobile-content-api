# frozen_string_literal: true

class TipsController < SecureController
  def create
    p = Tip.create!(params.require(:data).require(:attributes)
                       .permit(:filename, :structure, :resource_id))

    response.headers["Location"] = "tips/#{p.id}"
    render json: p, status: :created
  end

  def update
    tip = Tip.find(params[:id])
    tip.update!(params.require(:data).require(:attributes).permit(:structure))
    render json: tip, status: :ok
  end
end
