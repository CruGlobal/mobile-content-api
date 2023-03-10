class DeletionRequestsController < ApplicationController
  # disable CSRF protection, as it doesn't make sense in this case
  protect_from_forgery with: :null_session

  def facebook
    begin
      dr = DeletionRequest.from_signed_fb(params["signed_request"])
    rescue DeletionRequest::FailedAuthentication => e
      render json: { "error" => e.to_s }
      return
    end

    dr.run

    render json: {
      url: deletion_request_url(dr.pid),
      confirmation_code: dr.pid
    }
  end

  def show
    dr = DeletionRequest.find_by_pid!(params[:id])
    render json: { "data" => dr.deleted? ?  "Your data has been completely deleted" : "Your deletion request is still in progress" }
  end
end
