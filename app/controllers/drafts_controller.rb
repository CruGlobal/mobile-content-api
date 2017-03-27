# frozen_string_literal: true

require 'rest-client'
require 'digest/md5'
require 'aws-sdk-rails'
require 's3_helper'

class DraftsController < ApplicationController
  def page
    translation = Translation.find(params[:draft_id])
    page_name = Page.find(params[:page_id]).filename

    begin
      result = PageHelper.download_translated_page(translation, page_name)
    rescue RestClient::ExceptionWithResponse => e
      result = e.response
    end

    render json: result
  end

  def create_draft
    resource_id = params[:resource_id]
    language_id = params[:language_id]

    existing_translation = Translation.latest_translation(resource_id, language_id)

    if existing_translation.nil?
      resource = Resource.find(resource_id)
      language = Language.find(language_id)

      PageHelper.push_new_onesky_translation(resource, language.abbreviation)

      Translation.create(resource: resource, language: language)
    else
      existing_translation.add_new_version
    end

    :created
  end

  def publish_draft
    translation = Translation.find(params[:id])

    S3Helper.push_translation(translation)
    translation.update(is_published: true)
  end
end
