# frozen_string_literal: true

class CustomPagesController < ApplicationController
  def create
    head(upsert_custom_page)
  end

  def upsert_custom_page
    CustomPage.upsert(params)
  end
end
