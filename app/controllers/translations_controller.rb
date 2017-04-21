# frozen_string_literal: true

class TranslationsController < ApplicationController
  def index
    render json: all_translations, include: params[:include], status: :ok
  end

  def show
    redirect
  end

  private

  def all_translations
    if params['filter']
      Translation.is_published(params['filter']['is_published'])
    else
      Translation.all
    end
  end

  def redirect
    translation = Translation.find(params[:id])
    redirect_to translation.s3_uri, status: :found
  end
end
