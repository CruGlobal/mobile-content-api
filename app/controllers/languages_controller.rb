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
    language = Language.create!(params.require(:data).require(:attributes).permit([:name, :code]))
    head :created, location: "languages/#{language.id}"
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
