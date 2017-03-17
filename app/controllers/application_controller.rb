class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session #todo change back to :exception
end
