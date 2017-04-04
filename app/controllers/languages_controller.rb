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
    render json: Language.all, status: 200
  end

  def language
    render json: Language.find(params[:id]), status: 200
  end
end
