# frozen_string_literal: true

class TranslationsController < ApplicationController
  def index
    render json: all_translations, include: params[:include], status: :ok
  end

  def show
    id = params[:id]
    @translation = Translation.find(id)

    if @translation.is_published
      redirect
    else
      raise Error::NotFoundError, "Translation with ID: #{id} not found. " \
                                  "Use drafts/{id} if you're looking for an unpublished translation."
    end
  end

  private

  def all_translations
    Translation.where(is_published: true)
  end

  def redirect
    redirect_to @translation.s3_url, status: :found
  end
end
