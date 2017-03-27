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
    resource = Resource.find(params[:resource_id])
    language = Language.find(params[:language_id])

    result = PageHelper.push_new_onesky_translation(resource, language.abbreviation)

    Translation.create(
      resource: resource,
      language: language
    )

    result
  end

  def publish_draft
    translation = Translation.find(params[:id])

    S3Helper.push_translation(translation)
  end
end
