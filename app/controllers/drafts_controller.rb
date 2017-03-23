# frozen_string_literal: true

require 'rest-client'
require 'digest/md5'
require 'zip'
require 'aws-sdk-rails'
require 'page_helper'
require 's3_helper'

class DraftsController < ApplicationController
  def page
    translation = Translation.where(id: params[:draft_id]).first
    page_name = Page.where(id: params[:page_id]).first.filename

    begin
      result = PageHelper.download_translated_page(translation, page_name)
    rescue RestClient::ExceptionWithResponse => e
      result = e.response
    end

    render json: result
  end

  def create_draft
    resource = Resource.where(id: params[:resource_id]).first
    language = Language.where(id: params[:language_id]).first

    result = PageHelper.push_new_onesky_translation(resource, language.abbreviation)

    Translation.create(
      id: SecureRandom.uuid,
      resource: resource,
      language: language
    )

    result
  end

  def publish_draft
    translation = Translation.where(id: params[:id]).first

    S3Helper.push_translation(translation)
  end
end
