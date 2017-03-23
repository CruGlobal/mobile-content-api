# frozen_string_literal: true

class TranslationsController < ApplicationController
  def download_translated_resource
    translation = Translation.where(id: params[:id]).first

    resource = translation.resource
    system = resource.system
    language = translation.language

    path = "https://s3.amazonaws.com/#{ENV['GODTOOLS_V2_BUCKET']}/"\
    "#{system.name}/#{resource.abbreviation}/#{language.abbreviation}.zip"

    redirect_to path, status: 302
  end
end
