# frozen_string_literal: true
Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  resources :systems, :auth, :translations, :drafts, :resources, :custom_pages, :languages, :attributes,
            :translated_attributes
end
