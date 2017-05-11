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
      @translation.errors.add(:message, 'Translation not found. '\
                                        "Use drafts/{id} if you're looking for an unpublished translation.")
      render_error(@translation, :not_found)
    end
  end

  private

  def all_translations
    Translation.where(is_published: true)
  end

  def redirect
    redirect_to @translation.s3_uri, status: :found
  end
end
