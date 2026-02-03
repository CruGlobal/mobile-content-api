# frozen_string_literal: true

class LanguagesController < ApplicationController
  before_action :authorize!, only: [:create, :update, :destroy]
  before_action :convert_hyphen_to_dash, only: [:create, :update]

  def index
    render json: Language.all.order(name: :asc), include: params[:include], fields: field_params, status: :ok
  end

  def show
    render json: load_language, include: params[:include], fields: field_params, status: :ok
  end

  def create
    language = Language.create!(permit_params(:name, :code, :direction, :force_language_name, :crowdin_code))
    response.headers["Location"] = "languages/#{language.id}"
    render json: language, status: :created
  rescue ActiveRecord::RecordNotUnique
    raise Error::BadRequestError, "Code #{data_attrs[:code]} already exists."
  end

  def update
    language = load_language
    language.update!(permit_params(:name, :direction, :force_language_name, :crowdin_code))
    response.headers["Location"] = "languages/#{language.id}"
    render json: language, status: :accepted
  rescue ActiveRecord::RecordInvalid => e
    render json: {errors: formatted_errors("record_invalid", e)}, status: :unprocessable_content
  end

  def destroy
    load_language.destroy!
    head :no_content
  rescue ActiveRecord::RecordNotDestroyed => e
    render json: {errors: formatted_errors("record_invalid", e)}, status: :unprocessable_content
  end

  private

  def load_language
    Language.find(params[:id])
  end
end
