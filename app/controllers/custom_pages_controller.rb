# frozen_string_literal: true

class CustomPagesController < ApplicationController
  def create
    head(upsert_custom_page)
  end

  def destroy
    custom_page = CustomPage.find(params[:id])
    custom_page.destroy
  end

  private

  def upsert_custom_page
    CustomPage.upsert(params)
  end
end
