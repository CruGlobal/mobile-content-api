# frozen_string_literal: true

class LanguagesController < ApplicationController
  before_action :authorize!, only: [:create, :destroy]

  def index
    render json: Language.all.order(name: :asc), include: params[:include], fields: field_params, status: :ok
  end

  def show
    render json: load_language, include: params[:include], fields: field_params, status: :ok
  end

  def create
    language = Language.create!(permit_params(:name, :code, :direction, :force_language_name))
    response.headers["Location"] = "languages/#{language.id}"
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
