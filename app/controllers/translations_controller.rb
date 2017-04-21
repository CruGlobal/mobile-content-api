# frozen_string_literal: true

class TranslationsController < ApplicationController
  def index
    render json: all_translations, include: params[:include], status: :ok
  end

  def show
    @translation = Translation.find(params[:id])
    if @translation.is_published
      redirect
    else
      render_not_found
    end
  end

  private

  def all_translations
    Translation.where(is_published: true)
  end

  def render_not_found
    @translation.errors.add(:message, 'Translation not found.')
    render json: @translation,
           status: :not_found,
           adapter: :json_api,
           serializer: ActiveModel::Serializer::ErrorSerializer
  end

  def redirect
    redirect_to @translation.s3_uri, status: :found
  end
end
