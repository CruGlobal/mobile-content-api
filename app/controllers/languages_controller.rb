# frozen_string_literal: true

class LanguagesController < ApplicationController
  def index
    all_languages
  end

  def show
    language
  end

  private

  def all_languages
    render json: Language.all, status: :ok
  end

  def language
    render json: Language.find(params[:id]), status: :ok
  end
end
