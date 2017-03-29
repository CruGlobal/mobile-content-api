# frozen_string_literal: true

class TranslationsController < ApplicationController
  def show
    redirect
  end

  private

  def redirect
    translation = Translation.find(params[:id])
    redirect_to translation.s3_uri, status: 302
  end
end
