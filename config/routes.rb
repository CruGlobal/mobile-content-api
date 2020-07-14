# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  resources :systems, only: [:index, :show]
  resources :languages
  resources :resource_types, only: [:index, :show]

  resources :resources do
    resources :languages, controller: :resource_languages, only: [:put, :show]
  end
  resources :drafts
  resources :translations, only: [:index, :show]
  resources :pages, only: [:create, :update, :show]
  resources :tips, only: [:create, :update, :show]
  resources :custom_pages, only: [:create, :update, :destroy, :show]
  resources :custom_tips, only: [:create, :update, :destroy, :show]

  resources :attributes, only: [:create, :update, :destroy, :show]
  resources :translated_attributes, only: [:create, :update, :destroy, :show]
  resources :translated_pages, only: [:create, :update, :destroy, :show]

  resources :views, only: [:create]
  resources :follow_ups, only: [:create]

  resources :attachments

  resources :auth, only: [:create, :show]

  resources :custom_manifests, only: [:create, :update, :destroy, :show]

  get "monitors/lb"
  get "monitors/commit"

  get "attachments/:id/download", to: "attachments#download"
  get "/analytics/global", to: "global_activity_analytics#show"

  put "resources/:id/onesky", to: "resources#push_to_onesky"

  mount ActionCable.server => "/cable"
  mount Raddocs::App => "/docs"
end
