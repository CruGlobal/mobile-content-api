# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session # TODO: Change back to :exception.
end
