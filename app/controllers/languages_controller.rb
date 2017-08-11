# frozen_string_literal: true

class LanguagesController < ApplicationController
  before_action :authorize!, only: [:create, :destroy]

  def index
    render json: Language.all, status: :ok
  end

  def show
    render json: load_language, status: :ok
  end

  def create
    language = Language.create!(data_attrs.permit(:name, :code))
    response.headers['Location'] = "languages/#{language.id}"
    render json: language, status: :created
  rescue ActiveRecord::RecordNotUnique
    raise Error::BadRequestError, "Code #{data_attrs[:code]} already exists."
  end

  def destroy
    load_language.destroy!
    head :no_content
  end

  private

  def load_language
    Language.find(params[:id])
  end
end
